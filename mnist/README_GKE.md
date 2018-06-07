This tutorial contains instructions to build an **end to end kubeflow app** on a GKE cluster with minimal prerequisites.  The mnist model is trained and served from a NFS mount.  This example is intended for beginners with zero/minimal experience in kubeflow.

This tutorial demonstrates 

* Train a simple MNIST Tensorflow model (*See mnist_model.py*)
* Export the trained Tensorflow model and serve using tensorflow-model-server
* Test/Predict images with a python client(*See mnist_client.py*)

# Prerequisites

 1. **GKE Cluster Requirements**
      
     All nodes of GKE cluster must have `Ubuntu` node image. Masters and slaves are recommended to have latest k8s version.


 2. **kubectl cli**

     Check if kubectl  is configured properly by accessing the cluster Info of your GKE cluster
          
        $kubectl cluster-info 
             
                       
 3. **Ksonnet**(Latest version:version: 0.10.2)
 
      Check ksonnet version
    
        $ks version
 

If above commands succeeds, you are good to go !


# Installation

1. Export necessary environment variables for your application.  Users may change values if needed.
 

       #Namespace to be used in k8s cluster for your application 
       NAMESPACE=kubeflow

       #Ksonnet app name 
       APP_NAME=mnist        
 
       #GITHUB version for official kubeflow components
       KUBEFLOW_GITHUB_VERSION=master

       #GITHUB version for ciscoai components 
       CISCOAI_GITHUB_VERSION=master       

       #Ksonnet environment name
       KF_ENV=nativek8s     

       #Name of the NFS Persistent Volume              
       NFS_PVC_NAME=nfs         
      
 2. Create namespace if not present

    
        kubectl create namespace ${NAMESPACE}
    

3. Initialize the ksonnet app and create ksonnet environment. Environment makes it easy to manage app versions(Say dev, prod, test)


       ks init ${APP_NAME}
       cd ${APP_NAME}
       ks env add ${KF_ENV}
       ks env set ${KF_ENV} --namespace ${NAMESPACE}
    

4. Add Ksonnet registries for adding prototypes.  Prototypes are ksonnet templates


       #Public registry that contains the official kubeflow components
       ks registry add kubeflow github.com/kubeflow/kubeflow/tree/${KUBEFLOW_GITHUB_VERSION}/kubeflow
 
       #Private registry that contains mnist example components
       ks registry add ciscoai github.com/CiscoAI/kubeflow-examples/tree/${CISCOAI_GITHUB_VERSION}/mnist/pkg


5.  Install necessary packages from registries


        ks pkg install kubeflow/core@${KUBEFLOW_GITHUB_VERSION}
        ks pkg install kubeflow/tf-serving@${KUBEFLOW_GITHUB_VERSION}
        ks pkg install kubeflow/tf-job@${KUBEFLOW_GITHUB_VERSION}

        ks pkg install ciscoai/nfs-server@${CISCOAI_GITHUB_VERSION}
        ks pkg install ciscoai/nfs-volume@${CISCOAI_GITHUB_VERSION}
        ks pkg install ciscoai/tf-mnistjob@${CISCOAI_GITHUB_VERSION}
    

6. Deploy kubeflow core components to K8s cluster. 


        ks generate kubeflow-core kubeflow-core
        ks apply ${KF_ENV} -c kubeflow-core
    

 7.  Deploy NFS server using Google Cloud launcher **(Optional step)**
             
        If you have already setup a NFS server, you can skip this step and proceed to step 8. Set `NFS_SERVER_IP`to ip of your NFS server. 
     
        If you don't have one, deploy NFS server at https://console.cloud.google.com/launcher/details/click-to-deploy-images/singlefs

       
  

8.   Deploy NFS PV/PVC in the k8s cluster **(Optional step)**

     If you have already created NFS PersistentVolume and PersistentVolumeClaim, you can skip this step and proceed to step 9.  
   
         #Replace `nfs-server-name` and `nfs-server-zone-name` with the values used in step 7
         NFS_SERVER_IP=`gcloud compute instances describe <nfs-server-name> --zone=<nfs-server-zone-name> --format='value(networkInterfaces[0].networkIP)'`

         ks generate nfs-volume nfs-volume  --name=${NFS_PVC_NAME}  --nfs_server_ip=${NFS_SERVER_IP} --mountpath=/data
         ks apply ${KF_ENV} -c nfs-volume



**Installation is complete now.**

# Setup

1. Clone the mnist example 


       git clone git@github.com:CiscoAI/kubeflow-examples.git
       cd kubeflow-examples/mnist


2. Create the mnist training Image and upload to DockerHub

   Point `DOCKER_BASE_URL` to your DockerHub account. If you don't have a DockerHub account, create one. 

       
       DOCKER_BASE_URL=docker.io/johnugeorge
       IMAGE=${DOCKER_BASE_URL}/tfmodel
       docker build . --no-cache  -f Dockerfile -t ${IMAGE}
       docker push ${IMAGE}

3. Start the training job

    Set training job specific environment variables in `envs` variable(comma separated key-value pair). These key-value pairs are passed on to the training job when created. 

    
       #Enviroment variables for mnist training job(See mnist_model.py)  
       TF_DATA_DIR=/mnt/data
       TF_MODEL_DIR=/mnt/model
       NFS_MODEL_PATH=/mnt/export
       TF_EXPORT_DIR=${NFS_MODEL_PATH}
    
       #Concatenate key-value pairs into a env variable
       ENV="TF_DATA_DIR=$TF_DATA_DIR,TF_EXPORT_DIR=$TF_EXPORT_DIR,TF_MODEL_DIR=$TF_MODEL_DIR”

       ks generate tf-mnistjob tfmnistjob

       #Set tf training job specific environment params
       ks param set tfmnistjob image ${IMAGE}
       ks param set tfmnistjob envs ${ENV}

       #Deploy and start training
       ks apply ${KF_ENV} -c tfmnistjob
    

4. Start TF serving on the trained results
    
    Note that `tfserving's modelPath` is set to `tfmnistjob's TF_EXPORT_DIR` so that tf serving pod automatically picks up the training results when training is completed.
    

       ks generate tf-serving tfserving --name=mnist
    
       #Set tf serving job specific environment params
       ks param set tfserving modelPath ${NFS_MODEL_PATH}
       ks param set tfserving modelStorageType nfs
       ks param set tfserving nfsPVC ${NFS_PVC_NAME}

       #Deploy and start serving
       ks apply ${KF_ENV} -c tfserving
    

5. Port forward to access the serving port locally


       SERVING_POD_NAME=`kubectl -n ${NAMESPACE} get pod -l=app=mnist -o jsonpath='{.items[0].metadata.name}'`
    
       kubectl -n ${NAMESPACE} port-forward ${SERVING_POD_NAME} 9000:9000 &


6. Run a sample client code to predict images(See mnist-client.py)


       virtualenv --system-site-packages env
       source ./env/bin/activate 
       easy_install -U pip
       pip install --upgrade tensorflow
       pip install tensorflow-serving-api
       pip install python-mnist
       pip install Pillow
    
       TF_MNIST_IMAGE_PATH=data/7.png python mnist_client.py
    
 You should see the following result
 
      Your model says the above number is... 7!
 
 Now try a different image in `data` directory :)

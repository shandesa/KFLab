This tutorial contains instructions to build an **end to end kubeflow app** on a
native Kubernetes cluster(non-cloud) with minimal prerequisites.  The mnist
model is trained and served from a NFS mount.  This example is intended for
beginners with zero/minimal experience in kubeflow.

This tutorial demonstrates:

* Train a simple MNIST Tensorflow model (*See mnist_model.py*)
* Export the trained Tensorflow model and serve using tensorflow-model-server
* Test/Predict images with a python client(*See mnist_client.py*)

# Prerequisites

1. **kubectl cli**

   Check if kubectl  is configured properly by accessing the cluster Info of your kubernetes cluster

       $kubectl cluster-info

 2. **Ksonnet**(Latest version:version: 0.11.0)

    Check ksonnet version

        $ ks version


If above commands succeeds, you are good to go !


# Installation

        ./install.bash

If there is any rate limit error from github, please follow the instructions at:
https://ksonnet.io/docs/tutorial#troubleshooting-github-rate-limiting-errors.

# Setup
1. Create the mnist training Image and upload to DockerHub

   Point `DOCKER_BASE_URL` to your DockerHub account. If you don't have a DockerHub account, create one.

       DOCKER_BASE_URL=docker.io/johnugeorge
       IMAGE=${DOCKER_BASE_URL}/tfmodel
       docker build . --no-cache  -f Dockerfile -t ${IMAGE}
       docker push ${IMAGE}


2. Run the training job setup script

       ./train.bash

3. Start TF serving on the trained results

        ./serve.bash   

5. Port forward to access the serving port locally


       ./portf.bash 


6. Run a sample client code to predict images(See mnist-client.py)


       virtualenv --system-site-packages env
       source ./env/bin/activate
       easy_install -U pip
       pip install --upgrade tensorflow
       pip install tensorflow-serving-api
       pip install python-mnist

       TF_MNIST_IMAGE_PATH=data/7.png python mnist_client.py

 You should see the following result

      Your model says the above number is... 7!

 Now try a different image in `data` directory :)

#!/usr/bin/env bash

# Uncomment the following two lines to step through each command and to print
# the command being executed.
set -x
trap read debug

#1. Read variables
source variables.bash

#2. Create namespace if not present
kubectl create namespace ${NAMESPACE}

#3. Initialize the ksonnet app and create ksonnet environment. Environment makes it easy to manage app versions(Say dev, prod, test)
ks init ${APP_NAME}
cd ${APP_NAME}
ks env add ${KF_ENV}
# Use ks delete ${KF_ENV} to cleanup
ks env set ${KF_ENV} --namespace ${NAMESPACE}

#4. Add Ksonnet registries for adding prototypes. Prototypes are ksonnet templates

## Public registry that contains the official kubeflow components
ks registry add kubeflow github.com/kubeflow/kubeflow/tree/${KUBEFLOW_GITHUB_VERSION}/kubeflow

## Private registry that contains ${APP_NAME} example components
ks registry add ciscoai github.com/CiscoAI/kubeflow-examples/tree/${CISCOAI_GITHUB_VERSION}/${APP_NAME}/pkg

#5. Install necessary packages from registries

ks pkg install kubeflow/core@${KUBEFLOW_GITHUB_VERSION}
ks pkg install kubeflow/tf-serving@${KUBEFLOW_GITHUB_VERSION}
ks pkg install kubeflow/tf-job@${KUBEFLOW_GITHUB_VERSION}

ks pkg install ciscoai/nfs-server@${CISCOAI_GITHUB_VERSION}
ks pkg install ciscoai/nfs-volume@${CISCOAI_GITHUB_VERSION}
ks pkg install ciscoai/tf-${APP_NAME}job@${CISCOAI_GITHUB_VERSION}

#6. Deploy kubeflow core components to K8s cluster.

# If you are doing this on GCP, you need to run the following command first:
# kubectl create clusterrolebinding your-user-cluster-admin-binding --clusterrole=cluster-admin --user=<your@email.com>

ks generate kubeflow-core kubeflow-core
ks apply ${KF_ENV} -c kubeflow-core

#7. If you have already setup a NFS server, you can skip this step and proceed
#   to next step.
#
# If you don't have one, deploy NFS server following the instructions at:
#    https://console.cloud.google.com/launcher/details/click-to-deploy-images/singlefs

# Set NFS_SERVER_IP to ip of your NFS server.
# check output of 'gcloud compute instances list'
NFS_SERVER_NAME="singlefs-2-vm"
NFS_SERVER_ZONE="asia-southeast1-a"
NFS_SERVER_IP=`gcloud compute instances describe ${NFS_SERVER_NAME} --zone=${NFS_SERVER_ZONE} --format='value(networkInterfaces[0].networkIP)'`

#8. Deploy NFS PV/PVC in the k8s cluster **(Optional step)**
# If you have already created NFS PersistentVolume and PersistentVolumeClaim,
echo "NFS Server IP: ${NFS_SERVER_IP}"
ks generate nfs-volume nfs-volume  --name=${NFS_PVC_NAME} --nfs_server_ip=${NFS_SERVER_IP}  --mountpath=/data
ks apply ${KF_ENV} -c nfs-volume

#### Installation is complete now ####

echo "Make sure that the pods are running"
kubectl get pods -n ${NAMESPACE}

echo "If you have created NFS Persistent Volume, ensure PVC is created and status is BOUND"
kubectl get pvc -n ${NAMESPACE}

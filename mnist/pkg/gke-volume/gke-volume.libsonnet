local k = import "k.libsonnet";

{
 parts:: {
    gkeStorageClass(name, namespace, storage_type) :: {
        apiVersion: "storage.k8s.io/v1",
        kind: "StorageClass",
        metadata: {
            name: name,
            namespace: namespace,
        },
        provisioner: "kubernetes.io/gce-pd",
        parameters: {
             type: storage_type
        }
    },

     gkePVC(name, namespace, storageclass, storage_request) :: {
        apiVersion: "v1",
        kind: "PersistentVolumeClaim",
        metadata: {
            name: name,
            namespace: namespace,
        },
        spec: {
            accessModes: [ "ReadWriteMany" ],
            storageClassName: storageclass,
            resources: {
                requests: {
                    storage: storage_request
                }
            }
        }
     }
  }
}

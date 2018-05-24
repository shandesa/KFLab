local k = import "k.libsonnet";

{
 parts:: {
     nfsdeployment(name, namespace):: {
      apiVersion: "extensions/v1beta1",
      kind: "Deployment",
      metadata: {
        name: name,
        namespace: namespace,
        labels: { 
             role: "nfs-server"    
        },
      },
      spec: {
        template: {
          metadata: {
            labels: {
                 role: "nfs-server"
            }
          },   
          spec: {
            containers: [ {
                 name: "nfs-server",
                 image: "jsafrane/nfs-data",
                 ports: [ {
                    name: "nfs",
                    containerPort: 2049,
                 }],
                securityContext: {
                     privileged: true 
                }
              }
            ],
          },
        },
      },
    },  // nfsdeployment

    nfsservice(name, namespace):: {
        kind: "Service",
        apiVersion: "v1",
        metadata: {
            name: name,
            namespace: namespace,
        },
        spec: {
            ports: [{ 
                port: 2049
            }],
            selector: {
                role: "nfs-server"
            }
        }
    }
  }
}

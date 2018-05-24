// @apiVersion 0.1
// @name io.ksonnet.pkg.nfs-volume
// @description NFS Persistent volume
// @shortDescription Create a NFS persistent volume claim
// @param name string Name for the nfs volume.
// @param nfs_server_ip string Cluster Ip address of nfs-server service
// @optionalParam namespace string null Namespace to use for the components


local k = import "k.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace,
};


local name = import "param://name";
local namespace = updatedParams.namespace;

local nfs_server_ip = import "param://nfs-server-ip";

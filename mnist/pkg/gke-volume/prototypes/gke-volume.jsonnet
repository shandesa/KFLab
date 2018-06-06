// @apiVersion 0.1
// @name io.ksonnet.pkg.gke-volume
// @description GKE Persistent volume
// @shortDescription Create a GKE persistent volume claim
// @param name string Name for the gke volume.
// @optionalParam namespace string null Namespace to use for the components
// @optionalParam storage_type string pd-standard Requested storageType 
// @optionalParam storage_request string 10Gi Total storage requested from the persistent volume


local k = import "k.libsonnet";
local gke = import "ciscoai/gke-volume/gke-volume.libsonnet";

// updatedParams uses the environment namespace if
// the namespace parameter is not explicitly set
local updatedParams = params {
  namespace: if params.namespace == "null" then env.namespace else params.namespace,
};


local name = import "param://name";
local namespace = updatedParams.namespace;


local storage_type = import "param://storage_type";
local storage_request = import "param://storage_request";


std.prune(k.core.v1.list.new([
  gke.parts.gkeStorageClass("gkePD", namespace, storage_type),
  gke.parts.gkePVC(name, namespace, "gkePD", storage_request)
]))


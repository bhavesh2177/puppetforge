# This class configures the RBAC roles for Kubernetes 1.10.x

class kubernetes_v1_13_0::cluster_roles (
  Optional[Boolean] $controller = $kubernetes_v1_13_0::controller,
  Optional[Boolean] $worker = $kubernetes_v1_13_0::worker,
  String $node_name = $kubernetes_v1_13_0::node_name,
  String $container_runtime = $kubernetes_v1_13_0::container_runtime,
  Optional[Array] $ignore_preflight_errors = ['ExternalEtcdVersion']
) {
  if $container_runtime == 'cri_containerd' {
    $preflight_errors = flatten(['Service-Docker',$ignore_preflight_errors])
    $cri_socket = '/run/containerd/containerd.sock'
  } else {
    $preflight_errors = $ignore_preflight_errors
    $cri_socket = undef
  }


  if $controller {
    kubernetes_v1_13_0::kubeadm_init { $node_name:
      ignore_preflight_errors => $preflight_errors,
      }
    }

  if $worker {
    kubernetes_v1_13_0::kubeadm_join { $node_name:
      cri_socket              => $cri_socket,
      ignore_preflight_errors => $preflight_errors,
    }
  }
}

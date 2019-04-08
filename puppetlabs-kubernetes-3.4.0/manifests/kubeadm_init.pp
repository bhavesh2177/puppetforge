# == kubernetes::kubeadm_init
define kubernetes_v1_12_0::kubeadm_init (
  String $node_name                             = $kubernetes_v1_12_0::node_name,
  Optional[String] $config                      = $kubernetes_v1_12_0::config_file,
  Boolean $dry_run                              = false,
  Array $path                                   = $kubernetes_v1_12_0::default_path,
  Optional[Array] $env                          = $kubernetes_v1_12_0::environment,
  Optional[Array] $ignore_preflight_errors      = undef,
) {
  $kubeadm_init_flags = kubeadm_init_flags({
    config                  => $config,
    dry_run                 => $dry_run,
    ignore_preflight_errors => $ignore_preflight_errors,
  })

  $exec_init = "kubeadm init ${kubeadm_init_flags}"
  $unless_init = "kubectl get nodes | grep ${node_name}"

  exec { 'kubeadm init':
    command     => $exec_init,
    environment => $env,
    path        => $path,
    logoutput   => true,
    timeout     => 0,
    unless      => $unless_init,
  }

  # This prevents a known race condition https://github.com/kubernetes/kubernetes/issues/66689
  kubernetes_v1_12_0::wait_for_default_sa { 'default': }
}

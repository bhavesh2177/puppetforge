# Class kubernetes config_worker, populates worker config files with joinconfig
class kubernetes_v1_10_0::config::worker (
  String $node_name                        = $kubernetes_v1_10_0::node_name,
  String $config_file                      = $kubernetes_v1_10_0::config_file,
  String $kubernetes_version               = $kubernetes_v1_10_0::kubernetes_version,
  String $kubernetes_cluster_name          = $kubernetes_v1_10_0::kubernetes_cluster_name,
  String $controller_address               = $kubernetes_v1_10_0::controller_address,
  String $discovery_token_hash             = $kubernetes_v1_10_0::discovery_token_hash,
  String $container_runtime                = $kubernetes_v1_10_0::container_runtime,
  String $discovery_token                  = $kubernetes_v1_10_0::token,
  String $tls_bootstrap_token              = $kubernetes_v1_10_0::token,
  String $token                            = $kubernetes_v1_10_0::token,
  Optional[String] $discovery_file         = undef,
  Optional[String] $feature_gates          = undef,
  Optional[String] $cloud_provider         = $kubernetes_v1_10_0::cloud_provider,
  Optional[String] $cloud_config           = $kubernetes_v1_10_0::cloud_config,
  Optional[Array] $kubelet_extra_arguments = $kubernetes_v1_10_0::kubelet_extra_arguments,
  Optional[Hash] $kubelet_extra_config     = $kubernetes_v1_10_0::kubelet_extra_config,
  Optional[Array] $ignore_preflight_errors = undef,
  Boolean $skip_ca_verification            = false,
  String $cgroup_driver                    = $kubernetes_v1_10_0::cgroup_driver,
) {
  # to_yaml emits a complete YAML document, so we must remove the leading '---'
  $kubelet_extra_config_yaml = regsubst(to_yaml($kubelet_extra_config), '^---\n', '')

  $template = $kubernetes_version ? {
    default => 'v1alpha3',
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("kubernetes_v1_10_0/${template}/config_worker.yaml.erb"),
  }
}

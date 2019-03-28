# Class kubernetes config kubeadm, populates kubeadm config file with params to bootstrap cluster
class kubernetes_v1_13_0::config::kubeadm (
  # Newly Added by Bhavesh
  String $etcd_name = $kubernetes_v1_13_0::etcd_name,
  String $etcd_cluster_token = $kubernetes_v1_13_0::etcd_cluster_token,
  String $keepalived_auth_pass = $kubernetes_v1_13_0::keepalived_auth_pass,
  String $keepalived_virtual_router_id = $kubernetes_v1_13_0::keepalived_virtual_router_id,
  # Addition End

  String $config_file = $kubernetes_v1_13_0::config_file,
  Boolean $manage_etcd = $kubernetes_v1_13_0::manage_etcd,
  String $etcd_install_method = $kubernetes_v1_13_0::etcd_install_method,
  String $kubernetes_version  = $kubernetes_v1_13_0::kubernetes_version,
  String $kubernetes_cluster_name  = $kubernetes_v1_13_0::kubernetes_cluster_name,
  String $etcd_ca_key = $kubernetes_v1_13_0::etcd_ca_key,
  String $etcd_ca_crt = $kubernetes_v1_13_0::etcd_ca_crt,
  String $etcdclient_key = $kubernetes_v1_13_0::etcdclient_key,
  String $etcdclient_crt = $kubernetes_v1_13_0::etcdclient_crt,
  String $etcdserver_crt = $kubernetes_v1_13_0::etcdserver_crt,
  String $etcdserver_key = $kubernetes_v1_13_0::etcdserver_key,
  String $etcdpeer_crt = $kubernetes_v1_13_0::etcdpeer_crt,
  String $etcdpeer_key = $kubernetes_v1_13_0::etcdpeer_key,
  Array $etcd_peers = $kubernetes_v1_13_0::etcd_peers,
  String $etcd_ip = $kubernetes_v1_13_0::etcd_ip,
  String $cni_pod_cidr = $kubernetes_v1_13_0::cni_pod_cidr,
  String $kube_api_advertise_address = $kubernetes_v1_13_0::kube_api_advertise_address,
  String $etcd_initial_cluster = $kubernetes_v1_13_0::etcd_initial_cluster,
  String $etcd_initial_cluster_state = $kubernetes_v1_13_0::etcd_initial_cluster_state,
  Integer $api_server_count = $kubernetes_v1_13_0::api_server_count,
  String $etcd_version = $kubernetes_v1_13_0::etcd_version,
  String $token = $kubernetes_v1_13_0::token,
  String $discovery_token_hash = $kubernetes_v1_13_0::discovery_token_hash,
  String $kubernetes_ca_crt = $kubernetes_v1_13_0::kubernetes_ca_crt,
  String $kubernetes_ca_key = $kubernetes_v1_13_0::kubernetes_ca_key,
  String $container_runtime = $kubernetes_v1_13_0::container_runtime,
  String $sa_pub = $kubernetes_v1_13_0::sa_pub,
  String $sa_key = $kubernetes_v1_13_0::sa_key,
  Optional[Array] $apiserver_cert_extra_sans = $kubernetes_v1_13_0::apiserver_cert_extra_sans,
  Optional[Array] $apiserver_extra_arguments = $kubernetes_v1_13_0::apiserver_extra_arguments,
  Optional[Array] $kubelet_extra_arguments = $kubernetes_v1_13_0::kubelet_extra_arguments,
  String $service_cidr = $kubernetes_v1_13_0::service_cidr,
  String $node_name = $kubernetes_v1_13_0::node_name,
  Optional[String] $cloud_provider = $kubernetes_v1_13_0::cloud_provider,
  Optional[String] $cloud_config = $kubernetes_v1_13_0::cloud_config,
  Optional[Hash] $kubeadm_extra_config = $kubernetes_v1_13_0::kubeadm_extra_config,
  Optional[Hash] $kubelet_extra_config = $kubernetes_v1_13_0::kubelet_extra_config,
  String $image_repository = $kubernetes_v1_13_0::image_repository,
  String $cgroup_driver = $kubernetes_v1_13_0::cgroup_driver,
) {

  $kube_dirs = ['/etc/kubernetes','/etc/kubernetes/manifests','/etc/kubernetes/pki','/etc/kubernetes/pki/etcd']
  $etcd = ['ca.crt', 'ca.key', 'client.crt', 'client.key','peer.crt', 'peer.key', 'server.crt', 'server.key']
  $pki = ['ca.crt', 'ca.key','sa.pub','sa.key']
  $kube_dirs.each | String $dir |  {
    file  { $dir :
      ensure  => directory,
      mode    => '0600',
      recurse => true,
    }
  }

  if $manage_etcd {
    $etcd.each | String $etcd_files | {
      file { "/etc/kubernetes/pki/etcd/${etcd_files}":
        ensure  => present,
        content => template("kubernetes_v1_13_0/etcd/${etcd_files}.erb"),
        mode    => '0600',
      }
    }
    if $etcd_install_method == 'wget' {
      file { '/etc/systemd/system/etcd.service':
        ensure  => present,
        content => template('kubernetes_v1_13_0/etcd/etcd.service.erb'),
      }
    } else {
      file { '/etc/default/etcd':
        ensure  => present,
        content => template('kubernetes_v1_13_0/etcd/etcd.erb'),
      }
    }
  }

  $pki.each | String $pki_files | {
    file {"/etc/kubernetes/pki/${pki_files}":
      ensure  => present,
      content => template("kubernetes_v1_13_0/pki/${pki_files}.erb"),
      mode    => '0600',
    }
  }

  # The alpha1 schema puts Kubelet configuration in a different place.
  $kubelet_extra_config_alpha1 = {
    'kubeletConfiguration' => {
      'baseConfig' => $kubelet_extra_config,
    },
  }

  # Need to merge the cloud configuration parameters into extra_arguments
  if $cloud_provider {
    $cloud_args = $cloud_config ? {
      undef   => ["cloud-provider: ${cloud_provider}"],
      default => ["cloud-provider: ${cloud_provider}", "cloud-config: ${cloud_config}"],
    }
    $apiserver_merged_extra_arguments = concat($apiserver_extra_arguments, $cloud_args)
    $controllermanager_merged_extra_arguments = $cloud_args

    # could check against Kubernetes 1.10 here, but that uses alpha1 config which doesn't have these options
    if $cloud_config {
      # The cloud config must be mounted into the apiserver and controllermanager containers
      $controllermanager_extra_volumes = $apiserver_extra_volumes = {
        'cloud' => {
          hostPath  => $cloud_config,
          mountPath => $cloud_config,
        }
      }
    }
  }
  else {
    $apiserver_merged_extra_arguments = $apiserver_extra_arguments
    $apiserver_extra_volumes = {}
    $controllermanager_merged_extra_arguments = []
    $controllermanager_extra_volumes = {}
  }

  # to_yaml emits a complete YAML document, so we must remove the leading '---'
  $kubeadm_extra_config_yaml = regsubst(to_yaml($kubeadm_extra_config), '^---\n', '')
  $kubelet_extra_config_yaml = regsubst(to_yaml($kubelet_extra_config), '^---\n', '')
  $kubelet_extra_config_alpha1_yaml = regsubst(to_yaml($kubelet_extra_config_alpha1), '^---\n', '')

  $config_version = $kubernetes_version ? {
    /1.1(0|1)/ => 'v1alpha1',
    default    => 'v1alpha3',
  }

  file { $config_file:
    ensure  => present,
    content => template("kubernetes_v1_13_0/${config_version}/config_kubeadm.yaml.erb"),
    mode    => '0600',
  }
}

class kubecontainer (
  # "kube-apiserver" parameters
  $api_logtostderr              = 'TRUE', 
  $api_loglevel                 = '4',
  $api_etcd_servers             = '',
  $api_addr                     = '',
  $api_port                     = '8080',
  $api_node_port                = '10250',
  $api_advt_addr                = '',
  $api_allow_priv               = 'FALSE',
  $api_svc_addr                 = '',
  $api_client_ca_file           = '/srv/kubernetes/ca.crt',
  $api_tls_crt_file             = '/srv/kubernetes/server.cert',
  $api_tls_key_file             = '/srv/kubernetes/server.key',
  $api_other_args               = '',

  # "kube-controllermanager" parameters    
  $ctrl_logtostderr             = 'TRUE',
  $ctrl_loglevel                = '4',
  $ctrl_master                  = '',
  $ctrl_root_ca_file            = '/srv/kubernetes/ca.crt',
  $ctrl_svc_ac_prv_file         = '/srv/kubernetes/server.key',
  $ctrl_other_args              = '',

  # "kube-scheduler" parameters
  $schd_logtostderr             = 'TRUE',  
  $schd_loglevel                = '4',
  $schd_master                  = '',
  $schd_other_args              = '',

  # "etcd" parameters
  $etcd_name                    = 'master', 
  $etcd_data_dir                = '/var/lib/etcd',
  $etcd_listen_urls             = 'http://0.0.0.0:4001',
  $etcd_advt_urls               = '',
  $etcd_cluster_token           = '',

  # "kubelet" parameters
  $nod_logtostderr              = 'TRUE',
  $nod_loglevel                 = '4',
  $nod_port                     = '10250', 
  $nod_hostname                 = 'slavenode',
  $nod_api_srv                  = '',
  $nod_allow_priv               = 'FALSE', 
  $nod_cluster_domain           = '',
  $nod_kube_reserved_cpu        = 'cpu=500m',
  $nod_kube_reserved_ram        = 'memory=512Mi',
  $nod_sys_reserved_cpu         = 'cpu=1500m',
  $nod_sys_reserved_ram         = 'memory=1536Mi',
  $nod_dns                      = '',
  $nod_sys_reserved_disk        = '20480',
  $nod_cadvisor_port            = '4194',
  $nod_kube_other_args          = '',

  # "kube-proxy" parameters
  $nod_proxy_logtostderr        = 'TRUE',
  $nod_proxy_loglevel           = '4',
  $nod_proxy_master             = '',
  $nod_proxy_other_args         = '',

  # "flannel" parameters
  $nod_flannel_etcd             = '',
  $nod_flannel_key              = '/coreos.com/network',
  $nod_flannel_net              = '',

  # "keepalived" parameters
  $keepalived_virtual_router_id = '',
  #$keepalived_priority          = '',
  $keepalived_auth_pass         = '',

  # Other parameters
  $conf_num_nodes               = '',
  $master_ip_addr               = '',
  $additional_master_ip_addr    = '',
  $virtual_master_ip            = '',
  $remove_master_ip_addr        = '',
  $svc_ip_range                 = '',
  $flannel_ip_range             = '',
  $conf_nod_addr                = '',
  $remove_nod_addr              = '',
  $dns_cluster_domain           = '',
  $api_admission_ctrl           = 'NamespaceLifecycle,NamespaceExists,LimitRanger,ServiceAccount,SecurityContextDeny,ResourceQuota',
  $dns_ip                       = '',


  # Management parameters
  $action                       = 'Install',
  $kubernetes_version		= '1.9.0',
  $multi_master                 = 'False',
  $cluster_name                 = '',
  $master_hostname              = '',
  $username                     = '',
  $password                     = '',
  $namespace                    = '',
  $core_per_vm                  = '',
  $memory_per_vm                = '',

  # SSL Certificate parameters
  $cfssl_url                    = 'https://pkg.cfssl.org/R1.2/cfssl_linux-amd64',
  $cfssljson_url                = 'https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64',  
  $ssldir                       = '/etc/kubernetes',
  $node_pvt_address             = $facts['networking']['interfaces']['eth2']['ip'],
  $node_fqdn                    = $facts['fqdn'],
  $etcd_ca_crt_pem              = '',
  $etcd_ca_key_pem              = '',
  $etcd_client_crt_pem          = '',
  $etcd_client_key_pem          = '',
  $etcd_server_crt_pem          = '',
  $etcd_server_key_pem          = '',
  $kubernetes_crt_pem           = '',
  $kubernetes_key_pem           = '',
  $kubernetes_sa_pub            = '',
  $kubernetes_sa_key            = '',

) {

  case $kubernetes_version {
  	'1.10.0': 	{ include kubecontainer::v1_10::setup }
  	'1.11.0': 	{ include kubecontainer::v1_11::setup }
  	'1.12.0': 	{ include kubecontainer::v1_12::setup }
  	'1.13.0': 	{ include kubecontainer::v1_13::setup }
  	'1.9.0': 	{ include kubecontainer::v1_9::setup }
  	'1.8.0': 	{ include kubecontainer::v1_8::setup }
  	'1.7.0': 	{ include kubecontainer::v1_7::setup }
  	'1.6.0': 	{ include kubecontainer::v1_6::setup }
  	'1.3.5': 	{ include kubecontainer::v1_3::setup }
	default:{ include kubecontainer::v1_9::setup } 
  }

}

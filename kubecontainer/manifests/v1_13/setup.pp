class kubecontainer::v1_13::setup inherits kubecontainer {

  $node_pvt_address = $kubecontainer::node_pvt_address
  $action_lower = inline_template('<%= scope.lookupvar("kubecontainer::action").downcase %>')
  $controller_address = inline_template('<%= scope.lookupvar("kubecontainer::virtual_master_ip").gsub(/\/.*/,"") %>')
  $dns_cluster_domain = inline_template('<%= scope.lookupvar("kubecontainer::dns_cluster_domain").downcase %>')
  $node_label = $kubecontainer::node_fqdn

  exec {'yum enable centos repo':
    path => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    command => '/usr/bin/yum clean all && mv -v /etc/yum.repos.d_backup/* /etc/yum.repos.d/'
  }

  if($action_lower == 'install') {

    include 'kubecontainer::v1_13::generate_certs'

    $local_etcd_name = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %><% end %><% end %>')
    $etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %>=https://<%= @node_pvt_address %>:2380<% end %><% end %>')

    class {'kubernetes_v1_13_0':
	# Newly Added Options (Out of Kubernetes Puppet Module)
        etcd_name               => $local_etcd_name,
	etcd_cluster_token	=> $kubecontainer::etcd_cluster_token,
        keepalived_auth_pass    => $kubecontainer::keepalived_auth_pass,
        keepalived_virtual_router_id => $kubecontainer::keepalived_virtual_router_id,
        virtual_master_ip       => $kubecontainer::virtual_master_ip,
        dns_cluster_domain	=> $dns_cluster_domain,
	#nod_sys_reserved_disk 	=> $kubecontainer::nod_sys_reserved_disk,

	# Kubernetes Class Built In
        apiserver_cert_extra_sans => [ "$dns_cluster_domain", "$controller_address" ],
        cni_network_provider    => "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
        cni_pod_cidr            => $kubecontainer::flannel_ip_range,
        container_runtime       => "docker",
        controller              => true,
        controller_address      => "$controller_address:$kubecontainer::api_port",
        create_repos            => true,
        disable_swap            => true,
        manage_kernel_modules   => true,
        manage_sysctl_settings  => true,
        node_label              => $node_label,  
        #docker_version          => "17.03.0.ce-1.el7.centos",
        docker_version          => "18.06.0.ce-3.el7.x86_64",
        #docker_package_name     => "docker-engine",
        docker_package_name     => "docker-ce",
        docker_yum_baseurl      => 'https://download.docker.com/linux/centos/7/$basearch/stable',
        docker_yum_gpgkey       => 'https://download.docker.com/linux/centos/gpg',
        etcd_version            => "3.1.12",
        #etcd_archive            => "etcd-v$etcd_version-linux-amd64.tar.gz",
        #etcd_source             => "https://github.com/coreos/etcd/releases/download/v${etcd_version}/${etcd_archive}",
        etcd_install_method     => "wget",
        etcd_package_name       => "etcd-server",
        etcd_ip                 => $node_pvt_address,
        etcd_initial_cluster    => $etcd_initial_cluster,
        etcd_initial_cluster_state => "new",
        etcd_peers              => $kubecontainer::master_ip_addr,
        image_repository        => "k8s.gcr.io",
        install_dashboard       => true,
        kube_api_advertise_address => $node_pvt_address,
        kubernetes_version      => $kubecontainer::kubernetes_version,
        kubernetes_package_version => $kubecontainer::kubernetes_version,
        kubernetes_yum_baseurl  => "https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64",
        kubernetes_yum_gpgkey   => "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg",
        manage_docker           => true,
        manage_etcd             => true,
        schedule_on_controller  => true,
        service_cidr            => $kubecontainer::svc_ip_range,
        worker                  => false,
        token                   => "invj0c.h781mm3tx82hj57g",
        kubelet_extra_arguments => ["cluster-domain: '$dns_cluster_domain'","port: '$kubecontainer::nod_port'","hostname-override: '$node_label'","kube-reserved: '$kubecontainer::nod_kube_reserved_cpu,$kubecontainer::nod_kube_reserved_ram'","system-reserved: '$kubecontainer::nod_sys_reserved_cpu,$kubecontainer::nod_sys_reserved_ram'","max-pods: '110'","allow-privileged: 'true'"],
        api_server_count        => 0,
        discovery_token_hash    => 'aa4c5dae816a87b13f82efb9500b1cee6b18ee06bb314de9de905024993a0fa0',
        kubernetes_ca_crt       => '',
        kubernetes_ca_key       => '',
        etcd_ca_key             => '',
        etcd_ca_crt             => '',
        etcdclient_key          => '',
        etcdclient_crt          => '',
        etcdserver_key          => '',
        etcdserver_crt          => '',
        etcdpeer_crt            => '',
        etcdpeer_key            => '',
        sa_key                  => '',
        sa_pub                  => ''
    }

  } elsif($action_lower == 'uninstall') {

  } elsif($action_lower == 'addmaster') {

    include 'kubecontainer::v1_13::generate_certs'

    $local_etcd_name = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %><% end %><% end %>')
    $etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %>=https://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::master_ip_addr").size - 1) %><% end %><% end %><% if value == @node_pvt_address %><% break %><% end %><% end -%>,<% scope.lookupvar("kubecontainer::additional_master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %>=https://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::additional_master_ip_addr").size - 1) %><% end %><% end %><% end -%>')

    # Add new Node to ETCD Cluster
    exec {"Add '$node_pvt_address' node to ETCD":
      path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
      command   => "curl --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/client.crt --key /etc/kubernetes/pki/etcd/client.key https://$controller_address:2379/v2/members -XPOST -H 'Content-Type: application/json' -d '{\"peerURLs\":[\"https://$node_pvt_address:2380\"]}'", 
      require   => Class['kubecontainer::v1_13::generate_certs']
    }

    class {'kubernetes_v1_13_0':
        # Newly Added Options (Out of Kubernetes Puppet Module)
        etcd_name               => $local_etcd_name,
        etcd_cluster_token      => $kubecontainer::etcd_cluster_token,
        keepalived_auth_pass    => $kubecontainer::keepalived_auth_pass,
        keepalived_virtual_router_id => $kubecontainer::keepalived_virtual_router_id,
        virtual_master_ip      => $kubecontainer::virtual_master_ip,
        dns_cluster_domain	=> $dns_cluster_domain,
        #nod_sys_reserved_disk  => $kubecontainer::nod_sys_reserved_disk,

        # Kubernetes Class Built In
        apiserver_cert_extra_sans => [ "$dns_cluster_domain", "$controller_address" ],
        cni_network_provider    => "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
        cni_pod_cidr            => $kubecontainer::flannel_ip_range,
        container_runtime       => "docker",
        controller              => true,
        controller_address      => "$controller_address:$kubecontainer::api_port",
        create_repos            => true,
        disable_swap            => true,
        manage_kernel_modules   => true,
        manage_sysctl_settings  => true,
        node_label              => $node_label,  
        #docker_version          => "17.03.0.ce-1.el7.centos",
        docker_version          => "18.06.0.ce-3.el7.x86_64",
        #docker_package_name     => "docker-engine",
        docker_package_name     => "docker-ce",
        docker_yum_baseurl      => 'https://download.docker.com/linux/centos/7/$basearch/stable',
        docker_yum_gpgkey       => 'https://download.docker.com/linux/centos/gpg',
        etcd_version            => "3.1.12",
        #etcd_archive            => "etcd-v$etcd_version-linux-amd64.tar.gz",
        #etcd_source             => "https://github.com/coreos/etcd/releases/download/v${etcd_version}/${etcd_archive}",
        etcd_install_method     => "wget",
        etcd_package_name       => "etcd-server",
        etcd_ip                 => $node_pvt_address,
        etcd_initial_cluster    => $etcd_initial_cluster,
        etcd_initial_cluster_state => "existing",
        etcd_peers              => $kubecontainer::master_ip_addr,
        image_repository        => "k8s.gcr.io",
        install_dashboard       => false,
        kube_api_advertise_address => $node_pvt_address,
        kubernetes_version      => $kubecontainer::kubernetes_version,
        kubernetes_package_version => $kubecontainer::kubernetes_version,
        kubernetes_yum_baseurl  => "https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64",
        kubernetes_yum_gpgkey   => "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg",
        manage_docker           => true,
        manage_etcd             => true,
        schedule_on_controller  => true,
        service_cidr            => $kubecontainer::svc_ip_range,
        worker                  => false,
        token                   => "invj0c.h781mm3tx82hj57g",
        kubelet_extra_arguments => ["cluster-domain: '$dns_cluster_domain'","port: '$kubecontainer::nod_port'","hostname-override: '$node_label'","kube-reserved: '$kubecontainer::nod_kube_reserved_cpu,$kubecontainer::nod_kube_reserved_ram'","system-reserved: '$kubecontainer::nod_sys_reserved_cpu,$kubecontainer::nod_sys_reserved_ram'","max-pods: '110'","allow-privileged: 'true'"],
        api_server_count        => 0,
        discovery_token_hash    => 'aa4c5dae816a87b13f82efb9500b1cee6b18ee06bb314de9de905024993a0fa0',
        kubernetes_ca_crt       => '',
        kubernetes_ca_key       => '',
        etcd_ca_key             => '',
        etcd_ca_crt             => '',
        etcdclient_key          => '',
        etcdclient_crt          => '',
        etcdserver_key          => '',
        etcdserver_crt          => '',
        etcdpeer_crt            => '',
        etcdpeer_key            => '',
        sa_key                  => '',
        sa_pub                  => ''
    }

  } elsif($action_lower == 'removemaster') {

  } elsif($action_lower == 'addslave') {

    $local_etcd_name = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %><% end %><% end %>')
    $etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %>=https://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::master_ip_addr").size - 1) %><% end %><% end %><% if value == @node_pvt_address %><% break %><% end %><% end -%>,<% scope.lookupvar("kubecontainer::additional_master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %>=https://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::additional_master_ip_addr").size - 1) %><% end %><% end %><% end -%>')

    class {'kubernetes_v1_13_0':
        # Newly Added Options (Out of Kubernetes Puppet Module)
        etcd_name               => $local_etcd_name,
        etcd_cluster_token      => $kubecontainer::etcd_cluster_token,
        keepalived_auth_pass    => $kubecontainer::keepalived_auth_pass,
        keepalived_virtual_router_id => $kubecontainer::keepalived_virtual_router_id,
        virtual_master_ip      => $kubecontainer::virtual_master_ip,
        dns_cluster_domain	=> $dns_cluster_domain,
        #nod_sys_reserved_disk  => $kubecontainer::nod_sys_reserved_disk,

        # Kubernetes Class Built In
        apiserver_cert_extra_sans => [ "$dns_cluster_domain", "$controller_address" ],
        cni_network_provider    => "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
        cni_pod_cidr            => $kubecontainer::flannel_ip_range,
        container_runtime       => "docker",
        controller              => false,
        controller_address      => "$controller_address:$kubecontainer::api_port",
        create_repos            => true,
        disable_swap            => true,
        manage_kernel_modules   => true,
        manage_sysctl_settings  => true,
        node_label              => $node_label,  
        #docker_version          => "17.03.0.ce-1.el7.centos",
        docker_version          => "18.06.0.ce-3.el7.x86_64",
        #docker_package_name     => "docker-engine",
        docker_package_name     => "docker-ce",
        docker_yum_baseurl      => 'https://download.docker.com/linux/centos/7/$basearch/stable',
        docker_yum_gpgkey       => 'https://download.docker.com/linux/centos/gpg',
        ##etcd_version            => "3.1.12",
        #etcd_archive            => "etcd-v$etcd_version-linux-amd64.tar.gz",
        #etcd_source             => "https://github.com/coreos/etcd/releases/download/v${etcd_version}/${etcd_archive}",
        ##etcd_install_method     => "wget",
        ##etcd_package_name       => "etcd-server",
        ##etcd_ip                 => $node_pvt_address,
        ##etcd_initial_cluster    => $etcd_initial_cluster,
        ##etcd_initial_cluster_state => "existing",
        ##etcd_peers              => $kubecontainer::master_ip_addr,
        image_repository        => "k8s.gcr.io",
        install_dashboard       => false,
        kube_api_advertise_address => $node_pvt_address,
        kubernetes_version      => $kubecontainer::kubernetes_version,
        kubernetes_package_version => $kubecontainer::kubernetes_version,
        kubernetes_yum_baseurl  => "https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64",
        kubernetes_yum_gpgkey   => "https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg",
        manage_docker           => true,
        manage_etcd             => false,
        schedule_on_controller  => false,
        service_cidr            => $kubecontainer::svc_ip_range,
        worker                  => true,
        token                   => "invj0c.h781mm3tx82hj57g",
        kubelet_extra_arguments => ["cluster-domain: '$dns_cluster_domain'","port: '$kubecontainer::nod_port'","hostname-override: '$node_label'","kube-reserved: '$kubecontainer::nod_kube_reserved_cpu,$kubecontainer::nod_kube_reserved_ram'","system-reserved: '$kubecontainer::nod_sys_reserved_cpu,$kubecontainer::nod_sys_reserved_ram'","max-pods: '110'","allow-privileged: 'true'"],
        api_server_count        => 0,
        discovery_token_hash    => 'aa4c5dae816a87b13f82efb9500b1cee6b18ee06bb314de9de905024993a0fa0',
        kubernetes_ca_crt       => '',
        kubernetes_ca_key       => '',
        etcd_ca_key             => '',
        etcd_ca_crt             => '',
        etcdclient_key          => '',
        etcdclient_crt          => '',
        ##etcdserver_key          => '',
        ##etcdserver_crt          => '',
        ##etcdpeer_crt            => '',
        ##etcdpeer_key            => '',
        sa_key                  => '',
        sa_pub                  => ''
    }

  } elsif($action_lower == 'removeslave') {
  
  } 

}

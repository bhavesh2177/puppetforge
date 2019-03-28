class kubecontainer::v1_9::setup inherits kubecontainer {

  #$node_pvt_address = $facts['networking']['interfaces']['eth2']['ip']
  $node_pvt_address = $::ipaddress_eth1

  # Overriding the "Action" variable taken from UI (Only for Provisioning of Cluster)
  # If "conf_nod_addr" is empty and "node_pvt_address" is equal to 1st address of "master_ip_addr" then set "Action=Install" 
  # else "Action=Addmaster"
  # If "conf_nod_addr" not empty set "Action=Addslave"
  #
  #if(inline_template('<%= @action.downcase %>') == 'install') {
  #	if($node_pvt_address in $master_ip_addr) and ($node_pvt_address != $master_ip_addr[0])  {
  #   		$action_lower = 'addmaster'
  #	} elsif($node_pvt_address in $conf_nod_addr) {
  #		$action_lower = 'addslave'
  #	} else {
  #		$action_lower = inline_template('<%= @action.downcase %>')
  #	}
  #} else {
  #	$action_lower = inline_template('<%= @action.downcase %>')
  #}
  
  $action_lower = inline_template('<%= @action.downcase %>')

  # Turning Off Swap
  exec {"Turning Off Swap":
	path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
	command	=> "sed -i '/ swap / s/^/#/' /etc/fstab && swapoff -a",
	onlyif	=> "grep -E '^[^#].* swap .*' /etc/fstab",
  }
  
  if($action_lower == 'install') {

    $local_etcd_name = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %><% end %><% end %>')

    #$etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %><% end %><% end %>=http://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::master_ip_addr").size - 1) %><% end -%>')

    $etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %>=http://<%= @node_pvt_address %>:2380<% end %><% end %>')

    # Stop Firewall Service On Boot
    service {"Stop Firewalld Service":
      name        => 'firewalld.service',
      ensure      => 'stopped',
      enable      => 'false',
    }

    class {'kubernetes_v1_9_0':
	# Newly Added Options (Out of Kubernetes Puppet Module)
        dns_ip                  => $kubecontainer::dns_ip,                          
        dns_cluster_domain      => $kubecontainer::dns_cluster_domain,
        svc_ip_range            => $kubecontainer::svc_ip_range,
        flannel_ip_range        => $kubecontainer::flannel_ip_range,
        api_port                => $kubecontainer::api_port,
        virtual_master_ip       => $kubecontainer::virtual_master_ip,
        etcd_initial_cluster_state => 'new',
	etcd_cluster_token	=> $kubecontainer::etcd_cluster_token,
        keepalived_auth_pass    => $kubecontainer::keepalived_auth_pass,
        keepalived_virtual_router_id => $kubecontainer::keepalived_virtual_router_id,
	nod_port 		=> $kubecontainer::nod_port,
	nod_address		=> $node_pvt_address,
	nod_kube_reserved_cpu 	=> $kubecontainer::nod_kube_reserved_cpu,
	nod_kube_reserved_ram 	=> $kubecontainer::nod_kube_reserved_ram,
	nod_sys_reserved_cpu 	=> $kubecontainer::nod_sys_reserved_cpu,
	nod_sys_reserved_ram 	=> $kubecontainer::nod_sys_reserved_ram,
	nod_sys_reserved_disk 	=> $kubecontainer::nod_sys_reserved_disk,

	# Kubernetes Class Built In
        kubernetes_version      => '1.9.0-0',
        kubernetes_package_version => '1.9.0-0',
        cni_version             => '0.6.0-0',
        container_runtime       => 'docker',
        controller              => true,
        bootstrap_controller    => true,
        worker                  => false,
        manage_epel             => true,
        kube_api_advertise_address => $node_pvt_address,
        etcd_version            => '3.0.17',
        etcd_name		=> $local_etcd_name,
        etcd_ip                 => $node_pvt_address,
        etcd_initial_cluster    => $etcd_initial_cluster,
        sa_key                  => '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAz4Yx1pCDLnfkYQnn+8Q5KHgyjZZM9sNh84a/PH4Co9m4SF32
nkxhMzbWcb7e/rlCJJ43TenlB/YdMw66t6q7N+pz98dW7IZOwOINxhhrAHUTdeIV
6qTKtp+FkxjFtvAduJBo2HVaRXHkhyw9nON+OqK8dMnSUo0M/U0ufgxNQR89t9Pb
9dFzoJxd02i0fFBvY3hs5qQ9nkAFc+Mo8dWCLmaMDKEL9T+hhasCX92e10Ibr0si
paSpDpJ+gOdHyfxrHgYCZVznDCmTnWvsMg0lf8HLhsUEls1hTMOnaNhdH/VP2GnB
+IaPd44MALvLYGakL5WryGkPxPtGoG1cIC1iTQIDAQABAoIBAQC6hhpbiW5vINHD
qpy5PShGyKpfen1YukpbEXzniTckQHeTi+kzZOFkn+BlQjK6bpcVxKNew2DZJAwg
rReEJ8+4tWFgjuoBE8LLOSM6Lw5VzeUc6oXabh3JwV3U1co34GBGWH30OJ5XlsPZ                                                   
/xit4Ae/+i87JX+GNUM8lNe58aKqaSOiyfWwjK78nn9BYtm74aVs0L7GE5kXhE3S                                                   
nhX7qfzsm85aPwqxVbZ3bnn9m5WziMMDpC/lvkryxEJgJzkPIsCW9ljE34nm5Duk                                                   
vazXyj6RPBGmUVcL2OX9ywkgv2wS31NkKC/BIegYvdWvdLIhwbNoO5OsYlKvGx3O                                                   
ZEau298hAoGBAPgG/n87PE/lZABO8+2V41ztiQnnSm5j5v5tWs6ceyADwJSWzb7P                                                   
epQlZC0/9r0jIIjulTgV5SB2H8zcrsRRQ9Wo2q2gEwhSi9kvFPjV32vwLJAh9yCs                                                   
24AyGz1N6/m7TZLtrYDTSdJF5p0wGbbsfPb8SH02ZNnP9zSDyv1EIeLlAoGBANYx                                                   
5vLFiGdNI4OKeHUdP7vHMPBdQvHN1el9ljoazdujdYSPnNwJk1o775OQrFlAmrF/                                                   
s9qaduwZz0EFtQrY6VRcSNHdSkH+fH4BLiXkoz9Pia0yKRxgQpOA7oUTx9JrLmAT                                                   
dGcbMNoOoUyAj6ViiuqEpBSIpYL1EsGWWg60vwNJAoGAUA/Z6PITFutCK4NQ5Bll                                                   
KiMXAFZjxVyEPQ7JqDYE3KG5cX14bqaEt/uV6bFjEUycfPcevdr7ek4HF9cIpyBg                                                   
WEDIThGE80PKFtJG38gR9cKyb9g28Jo7xJboChL0IEng0ZPdVN9fTfv4ZDcZpd2S                                                   
vRtUvu5nAZRLBO2iAb0Tfy0CgYEAjWMLS51QWL/2fVHeCZBxDYaCq2ckVXDFjwaz                                                   
L0+aKy1O2V3i8OvxNFLz5bhNy+x1ME1Xbyke7uJqiEU4KBzeiC0SdFVaOw29J3+n                                                   
8qNljtj1zDmcIXr491zYFUflUuQlDI5K+/Ra3tVha5pBN65AfGVp2ZQJjNQwuVCB                                                   
yctNeuECgYAiVkbKHk4JGgAlxguk+8ME4/SlV2i4rVjrf9dCuN+iR3x9phh1n4zC                                                   
8ktKG2OYAkL+dDSyZbhBgQ/KgBUcy7JedkEruIzhxpJdQ8PmApjg60Pun53T2h/G                                                   
n5f76g6mGUd8IdakTHMfG6NHc4NFgmWAoF02sHIrrqqBp4Rx++ltqA==                                                           
-----END RSA PRIVATE KEY-----',
    }

    ## Enabling CNI network configuration for the Kubelet on Bootstrap Controller Node
    exec { 'Enable CNI in Kubelet':
      path      => '/bin', 
      command   => "sed -i '/^#Environment=.KUBELET_NETWORK_ARGS=/ s/^#//g' /etc/systemd/system/kubelet.service.d/kubernetes.conf && systemctl daemon-reload && systemctl restart kubelet",
      require  => Class['kubernetes_v1_9_0'],
    }
  
    #kubecontainer::v1_9::function_limitrange_per_namespace {"limitrange_per_namespace_$node_pvt_address": 
    #  name_space => "$namespace", 
    #  total_cpu_cores => "$core_per_vm", 
    #  total_memory_gb => "$memory_per_vm",
    #  require	=> Class['kubernetes_v1_9_0'],
    #}

  } elsif($action_lower == 'uninstall') {

  } elsif($action_lower == 'addmaster') {

    $local_etcd_name = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %><% end %><% end %>')

    #$etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %><% end %><% end %>=http://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::master_ip_addr").size - 1) %><% end -%>,<% scope.lookupvar("kubecontainer::additional_master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %><% end %><% end %>=http://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::additional_master_ip_addr").size - 1) %><% end -%>')

    $etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %>=http://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::master_ip_addr").size - 1) %><% end %><% end %><% if value == @node_pvt_address %><% break %><% end %><% end -%>,<% scope.lookupvar("kubecontainer::additional_master_ip_addr").each_with_index do |value, index| %><% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if value == ip %><%= name %>=http://<%= value %>:2380<%= "," if index < (scope.lookupvar("kubecontainer::additional_master_ip_addr").size - 1) %><% end %><% end %><% end -%>')

    # Stop Firewall Service On Boot
    service {"Stop Firewalld Service":
      name        => 'firewalld.service',
      ensure      => 'stopped',
      enable      => 'false',
    }

    # Add new Node to ETCD Cluster
    #$etcd_first_master = $master_ip_addr[0]
    $etcd_first_master = inline_template('<%= @virtual_master_ip.gsub(/\/.*/,"") %>')
    exec {"Add '$node_pvt_address' node to ETCD":
	path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
	command	=> "curl http://$etcd_first_master:2379/v2/members -XPOST -H 'Content-Type: application/json' -d '{\"peerURLs\":[\"http://$node_pvt_address:2380\"]}'", 
	require => Class['kubernetes_v1_9_0'],
    }
    
    class {'kubernetes_v1_9_0':
	# Newly Added Options (Out of Kubernetes Puppet Module)
        dns_ip                  => $kubecontainer::dns_ip,                          
        dns_cluster_domain      => $kubecontainer::dns_cluster_domain,
        svc_ip_range            => $kubecontainer::svc_ip_range,
        flannel_ip_range        => $kubecontainer::flannel_ip_range,
        api_port                => $kubecontainer::api_port,
        virtual_master_ip       => $kubecontainer::virtual_master_ip,
        etcd_initial_cluster_state => 'existing',
	etcd_cluster_token	=> $kubecontainer::etcd_cluster_token,
        keepalived_auth_pass    => $kubecontainer::keepalived_auth_pass,
        keepalived_virtual_router_id => $kubecontainer::keepalived_virtual_router_id,
	nod_port 		=> $kubecontainer::nod_port,
	nod_address		=> $node_pvt_address,
	nod_kube_reserved_cpu 	=> $kubecontainer::nod_kube_reserved_cpu,
	nod_kube_reserved_ram 	=> $kubecontainer::nod_kube_reserved_ram,
	nod_sys_reserved_cpu 	=> $kubecontainer::nod_sys_reserved_cpu,
	nod_sys_reserved_ram 	=> $kubecontainer::nod_sys_reserved_ram,
	nod_sys_reserved_disk 	=> $kubecontainer::nod_sys_reserved_disk,

	# Kubernetes Class Built In
        kubernetes_version      => '1.9.0-0',
        kubernetes_package_version => '1.9.0-0',
        cni_version             => '0.6.0-0',
        container_runtime       => 'docker',
        controller              => true,
        bootstrap_controller    => false,
        worker                  => false,
        manage_epel             => true,
        kube_api_advertise_address => $node_pvt_address,
        etcd_version            => '3.0.17',
        etcd_name		=> $local_etcd_name,
        etcd_ip                 => $node_pvt_address,
        etcd_initial_cluster    => $etcd_initial_cluster,
        sa_key                  => '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAz4Yx1pCDLnfkYQnn+8Q5KHgyjZZM9sNh84a/PH4Co9m4SF32
nkxhMzbWcb7e/rlCJJ43TenlB/YdMw66t6q7N+pz98dW7IZOwOINxhhrAHUTdeIV
6qTKtp+FkxjFtvAduJBo2HVaRXHkhyw9nON+OqK8dMnSUo0M/U0ufgxNQR89t9Pb
9dFzoJxd02i0fFBvY3hs5qQ9nkAFc+Mo8dWCLmaMDKEL9T+hhasCX92e10Ibr0si
paSpDpJ+gOdHyfxrHgYCZVznDCmTnWvsMg0lf8HLhsUEls1hTMOnaNhdH/VP2GnB
+IaPd44MALvLYGakL5WryGkPxPtGoG1cIC1iTQIDAQABAoIBAQC6hhpbiW5vINHD
qpy5PShGyKpfen1YukpbEXzniTckQHeTi+kzZOFkn+BlQjK6bpcVxKNew2DZJAwg
rReEJ8+4tWFgjuoBE8LLOSM6Lw5VzeUc6oXabh3JwV3U1co34GBGWH30OJ5XlsPZ                                                   
/xit4Ae/+i87JX+GNUM8lNe58aKqaSOiyfWwjK78nn9BYtm74aVs0L7GE5kXhE3S                                                   
nhX7qfzsm85aPwqxVbZ3bnn9m5WziMMDpC/lvkryxEJgJzkPIsCW9ljE34nm5Duk                                                   
vazXyj6RPBGmUVcL2OX9ywkgv2wS31NkKC/BIegYvdWvdLIhwbNoO5OsYlKvGx3O                                                   
ZEau298hAoGBAPgG/n87PE/lZABO8+2V41ztiQnnSm5j5v5tWs6ceyADwJSWzb7P                                                   
epQlZC0/9r0jIIjulTgV5SB2H8zcrsRRQ9Wo2q2gEwhSi9kvFPjV32vwLJAh9yCs                                                   
24AyGz1N6/m7TZLtrYDTSdJF5p0wGbbsfPb8SH02ZNnP9zSDyv1EIeLlAoGBANYx                                                   
5vLFiGdNI4OKeHUdP7vHMPBdQvHN1el9ljoazdujdYSPnNwJk1o775OQrFlAmrF/                                                   
s9qaduwZz0EFtQrY6VRcSNHdSkH+fH4BLiXkoz9Pia0yKRxgQpOA7oUTx9JrLmAT                                                   
dGcbMNoOoUyAj6ViiuqEpBSIpYL1EsGWWg60vwNJAoGAUA/Z6PITFutCK4NQ5Bll                                                   
KiMXAFZjxVyEPQ7JqDYE3KG5cX14bqaEt/uV6bFjEUycfPcevdr7ek4HF9cIpyBg                                                   
WEDIThGE80PKFtJG38gR9cKyb9g28Jo7xJboChL0IEng0ZPdVN9fTfv4ZDcZpd2S                                                   
vRtUvu5nAZRLBO2iAb0Tfy0CgYEAjWMLS51QWL/2fVHeCZBxDYaCq2ckVXDFjwaz                                                   
L0+aKy1O2V3i8OvxNFLz5bhNy+x1ME1Xbyke7uJqiEU4KBzeiC0SdFVaOw29J3+n                                                   
8qNljtj1zDmcIXr491zYFUflUuQlDI5K+/Ra3tVha5pBN65AfGVp2ZQJjNQwuVCB                                                   
yctNeuECgYAiVkbKHk4JGgAlxguk+8ME4/SlV2i4rVjrf9dCuN+iR3x9phh1n4zC                                                   
8ktKG2OYAkL+dDSyZbhBgQ/KgBUcy7JedkEruIzhxpJdQ8PmApjg60Pun53T2h/G                                                   
n5f76g6mGUd8IdakTHMfG6NHc4NFgmWAoF02sHIrrqqBp4Rx++ltqA==                                                           
-----END RSA PRIVATE KEY-----',
    }

  } elsif($action_lower == 'removemaster') {

  } elsif($action_lower == 'addslave') {

    # Stop Firewall Service On Boot
    service {"Stop Firewalld Service":
      name        => 'firewalld.service',
      ensure      => 'stopped',
      enable      => 'false',
    }
  
    class {'kubernetes_v1_9_0':
	# Newly Added Options (Out of Kubernetes Puppet Module)
        dns_ip                  => $kubecontainer::dns_ip,                          
        dns_cluster_domain      => $kubecontainer::dns_cluster_domain,
        api_port                => $kubecontainer::api_port,
        virtual_master_ip       => $kubecontainer::virtual_master_ip,
	nod_port 		=> $kubecontainer::nod_port,
	nod_address		=> $node_pvt_address,
	nod_kube_reserved_cpu 	=> $kubecontainer::nod_kube_reserved_cpu,
	nod_kube_reserved_ram 	=> $kubecontainer::nod_kube_reserved_ram,
	nod_sys_reserved_cpu 	=> $kubecontainer::nod_sys_reserved_cpu,
	nod_sys_reserved_ram 	=> $kubecontainer::nod_sys_reserved_ram,
	nod_sys_reserved_disk 	=> $kubecontainer::nod_sys_reserved_disk,

	# Kubernetes Class Built In
        kubernetes_version      => '1.9.0-0',
        kubernetes_package_version => '1.9.0-0',
        cni_version             => '0.6.0-0',
        container_runtime       => 'docker',
        controller              => false,
        bootstrap_controller    => false,
        worker                  => true,
        manage_epel             => true,
    }

  } elsif($action_lower == 'removeslave') {
  
  } 

}

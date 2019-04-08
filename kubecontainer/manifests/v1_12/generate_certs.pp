class kubecontainer::v1_12::generate_certs inherits kubecontainer {

  $cfssl_url            = $kubecontainer::cfssl_url
  $cfssljson_url        = $kubecontainer::cfssljson_url
  $ssldir               = $kubecontainer::ssldir
  $node_pvt_address     = $kubecontainer::node_pvt_address
  $node_fqdn            = $kubecontainer::node_fqdn
  $ssl_dirs             = ["$ssldir","$ssldir/pki","$ssldir/pki/etcd"]
  $virtual_master_ip    = inline_template('<%= scope.lookupvar("kubecontainer::virtual_master_ip").gsub(/\/.*/,"") %>')

  file {'install_cfssl':
    path    => "/usr/local/bin/cfssl",
    mode    => "0755",
    source  => "puppet:///modules/kubecontainer/v1_12/downloads/cfssl"
  }

  file {'install_cfssljson':
    path    => "/usr/local/bin/cfssljson",
    mode    => "0755",
    source  => "puppet:///modules/kubecontainer/v1_12/downloads/cfssljson",
    require => File['install_cfssl']
  }

  $ssl_dirs.each | String $dir | {
    exec { "$dir":
      command => "mkdir $dir",
      provider => shell,
      before  => File["Create etcd-ca-csr.json"]
    }
  }

  file {"Create etcd-ca-csr.json":
    path    => "$ssldir/pki/etcd/ca-csr.json",
    content => template("kubecontainer/v1_12/ssl/etcd/ca-csr.json"),
  }

  file {"Create etcd-ca-conf.json":
    path    => "$ssldir/pki/etcd/ca-conf.json",
    content => template("kubecontainer/v1_12/ssl/etcd/ca-conf.json"),
    require => File["Create etcd-ca-csr.json"]
  }

  file {"Create etcd-client-csr.json":
    path    => "$ssldir/pki/etcd/client-csr.json",
    content => template("kubecontainer/v1_12/ssl/etcd/client-config.json"),
    require => File["Create etcd-ca-conf.json"]
  }

  file {"Create etcd-server-csr.json":
    path    => "$ssldir/pki/etcd/server-csr.json",
    content => template("kubecontainer/v1_12/ssl/etcd/server-config.json"),
    require => File["Create etcd-client-csr.json"]
  }

  file {"Create kubernetes-ca-csr.json":
    path    => "$ssldir/pki/ca-csr.json",
    content => template("kubecontainer/v1_12/ssl/kubernetes/ca-csr.json"),
    require => File["Create etcd-server-csr.json"]
  }

  file {"Create kubernetes-ca-conf.json":
    path    => "$ssldir/pki/ca-conf.json",
    content => template("kubecontainer/v1_12/ssl/kubernetes/ca-conf.json"),
    require => File["Create kubernetes-ca-csr.json"]
  }

  file {'ssl_etcd_ca_crt':
    path    => "$ssldir/pki/etcd/ca.crt",
    mode    => "0600",
    content => template("kubecontainer/v1_12/ssl/etcd/ca.crt"),
    require => File["Create kubernetes-ca-conf.json"]
  }

  file {'ssl_etcd_ca_key':
    path    => "$ssldir/pki/etcd/ca.key",
    mode    => "0644",
    content => template("kubecontainer/v1_12/ssl/etcd/ca.key"),
    require => File["ssl_etcd_ca_crt"]
  }

  exec {'ssl_etcd_client':
    path    => "/usr/bin:/bin:/usr/local/bin",
    command => "cd $ssldir/pki/etcd && cfssl gencert -ca=ca.crt -ca-key=ca.key -config=ca-conf.json -profile client client-csr.json | cfssljson -bare client",
    require => File['ssl_etcd_ca_key']
  }

  exec {'ssl_etcd_server':
    path    => "/usr/bin:/bin:/usr/local/bin",
    command => "cd $ssldir/pki/etcd && cfssl gencert -ca=ca.crt -ca-key=ca.key -config=ca-conf.json -profile server --hostname=$node_fqdn,$node_pvt_address,$virtual_master_ip server-csr.json | cfssljson -bare server",
    require => Exec['ssl_etcd_client']
  }

  exec {'ssl_etcd_peer':
    path    => "/usr/bin:/bin:/usr/local/bin",
    command => "cd $ssldir/pki/etcd && cfssl gencert -ca=ca.crt -ca-key=ca.key -config=ca-conf.json -profile peer --hostname=$node_fqdn,$node_pvt_address server-csr.json | cfssljson -bare peer",
    require => Exec['ssl_etcd_server']
  }

  file {'ssl_kubernetes_ca_crt':
    path    => "$ssldir/pki/ca.crt",
    mode    => "0644",
    content => template("kubecontainer/v1_12/ssl/kubernetes/ca.crt"),
    require => Exec['ssl_etcd_peer']
  }

  file {'ssl_kubernetes_ca_key':
    path    => "$ssldir/pki/ca.key",
    mode    => "0600",
    content => template("kubecontainer/v1_12/ssl/kubernetes/ca.key"),
    require => File['ssl_kubernetes_ca_crt']
  }

  file {'discovery_token_hash':
    path    => "$ssldir/pki/discovery_token_hash",
    mode    => "0644",
    content => template("kubecontainer/v1_12/ssl/kubernetes/discovery_token_hash"),
    require => File['ssl_kubernetes_ca_key']
  }

  file {'ssl_kubernetes_sa_pub':
    path    => "$ssldir/pki/sa.pub",
    mode    => "0644",
    content => template("kubecontainer/v1_12/ssl/kubernetes/sa.pub"),
    require => File['discovery_token_hash']
  }

  file {'ssl_kubernetes_sa_key':
    path    => "$ssldir/pki/sa.key",
    mode    => "0600",
    content => template("kubecontainer/v1_12/ssl/kubernetes/sa.key"),
    require => File['ssl_kubernetes_sa_pub']
  }

  exec {'rename PEM to crt/key':
    command => "for i in \$(ls -1 $ssldir/pki/*pem $ssldir/pki/etcd/*pem); do if [[ \$i =~ \"key\" ]]; then mv \$i \${i/-key*.pem/.key}; else mv \$i \${i/.pem/.crt}; fi ; done",
    require => File['ssl_kubernetes_sa_key'],
    provider => shell
  }

}

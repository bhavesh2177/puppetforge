class kubernetes_v1_13_0::keepalived (
  $virtual_master_ip = $kubernetes_v1_13_0::virtual_master_ip,
  $keepalived_virtual_router_id = $kubernetes_v1_13_0::keepalived_virtual_router_id,
  $keepalived_auth_pass = $kubernetes_v1_13_0::keepalived_auth_pass,
  $etcd_ip = $kubernetes_v1_13_0::etcd_ip,
) {

    package {'Keepalived Installation':
      name          => 'keepalived',
      ensure        => 'installed',
      provider      => 'yum',
      allow_virtual => false,
      before        => File['/etc/keepalived/keepalived.conf'],
    }

    file {'/etc/keepalived/keepalived.conf':
      mode          => '0600',
      content       => template('kubernetes_v1_13_0/keepalived/keepalived.erb'),
      source_permissions => ignore,
      backup        => ".origional",
    }

    file {'/etc/keepalived/checkService.sh':
      mode          => '0755',
      content       => template('kubernetes_v1_13_0/keepalived/checkService.sh.erb'),
      require       => Package['Keepalived Installation'],
    }

    service {"Enable 'keepalived' Service":
      name          => 'keepalived',
      enable        => 'true',
      ensure        => 'running',
      require       => Package['Keepalived Installation'],
    }

}

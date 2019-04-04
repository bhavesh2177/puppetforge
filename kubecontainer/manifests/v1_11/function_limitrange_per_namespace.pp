define kubecontainer::v1_11::function_limitrange_per_namespace (
  $name_space,
  $total_cpu_cores,
  $total_memory_gb,
) {
    $namespace = inline_template('<%= @name_space.downcase %>')
    exec {"Creating Namespace $namespace":
      path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/opt/kubernetes',
      command => "kubectl --kubeconfig=/etc/kubernetes/kubelet.conf create namespace $namespace && kubectl --kubeconfig=/etc/kubernetes/kubelet.conf config set-context centos --namespace='$namespace'",
    }
 
    $yaml_temp_file="/tmp/limit_range_$name_space.yaml"

    file { "$yaml_temp_file":
      content   => template('kubecontainer/master/limitrange.erb'),
      before    => Exec["Create Limit Range $name_space"],
    }
  
    exec { "Create Limit Range $name_space":
      path      => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin',
      command   => "kubectl --kubeconfig=/etc/kubernetes/kubelet.conf create -f $yaml_temp_file && rm -f $yaml_temp_file",
    }

}

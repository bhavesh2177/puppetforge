class kubecontainer::v1_13::setup inherits kubecontainer {

  $node_pvt_address = $facts['networking']['interfaces']['eth2']['ip']
  $action_lower = inline_template('<%= @action.downcase %>')
  $controller_address = inline_template('<% scope.lookupvar("kubecontainer::virtual_master_ip").gsub(/\/*/,"") %>')
  $local_etcd_name = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2
) %><% if ip == @node_pvt_address %><%= name %><% end %><% end %>')
  $etcd_initial_cluster = inline_template('<% scope.lookupvar("kubecontainer::etcd_name").each do |addr| %><% ip,name = addr.split(":",2) %><% if ip == @node_pvt_address %><%= name %>=https://<%= @node_pvt_address %>:2380<% end %><% end %>')

  if($action_lower == 'install') {

    class {'kubernetes_v1_13_0':
	# Newly Added Options (Out of Kubernetes Puppet Module)
        etcd_name               => $local_etcd_name,
	etcd_cluster_token	=> $kubecontainer::etcd_cluster_token,
        keepalived_auth_pass    => $kubecontainer::keepalived_auth_pass,
        keepalived_virtual_router_id => $kubecontainer::keepalived_virtual_router_id,
	#nod_sys_reserved_disk 	=> $kubecontainer::nod_sys_reserved_disk,

	# Kubernetes Class Built In
        apiserver_cert_extra_sans => [ "$kubecontainer::dns_cluster_domain" ],
        cni_network_provider    => "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
        cni_pod_cidr            => $kubecontainer::flannel_ip_range,
        container_runtime       => "docker",
        controller              => true,
        controller_address      => "$controller_address:$kubecontainer::api_port",
        create_repos            => true,
        disable_swap            => true,
        manage_kernel_modules   => true,
        manage_sysctl_settings  => true,
        #docker_version          => "17.03.0.ce-1.el7.centos",
        docker_version          => "18.06.0.ce-3.el7.x86_64",
        #docker_package_name     => "docker-engine",
        docker_package_name     => "docker-ce",
        docker_yum_baseurl      => "https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64",
        docker_yum_gpgkey       => "https://yum.dockerproject.org/gpg",
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
        kubelet_extra_arguments => ["cluster-dns: $kubecontainer::dns_ip","cluster-domain: $kubecontainer::dns_cluster_domain","port: $kubecontainer::nod_port","hostname-override: $node_pvt_address","kube-reserved: $kubecontainer::nod_kube_reserved_cpu,$kubecontainer::nod_kube_reserved_ram","system-reserved: $kubecontainer::nod_sys_reserved_cpu,$kubecontainer::nod_sys_reserved_ram","max-pods: 110","allow-privileged: true"],
        api_server_count        => 0,
        discovery_token_hash    => "d136377130dedfdaf7828895bc96e8b593bf775273d93933ea7a06364612be99",
        kubernetes_ca_crt       => "-----BEGIN CERTIFICATE-----
MIIDHjCCAgagAwIBAgIUSTQ7Z32ALI5EsNcM5WqovruIUlYwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKa3ViZXJuZXRlczAeFw0xOTAzMjcwNjU2MDBaFw0yNDAz
MjUwNjU2MDBaMBUxEzARBgNVBAMTCmt1YmVybmV0ZXMwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDp3ADvhpfurLp4EtCD174AR8GprU76fMiOWoBwqTDk
ceAyNJzNOzZ2XxKx/0kRFC5IjubyHbez9ebqEDq4YCAp5SjUWdGbQYctWAsOZdU0
r3TZkNPDkLPosKh3o0gcNQKenVOkcc6fh3oalOiV1Z1yqJ7wajMffLnIM+0E38SA
bY+3R5NVjWfZu8SoZ0O73pNuaUKYuYwmRh9xm3DZA9CYCUqPQFJo3Isgtabp7GPU
9/KTPb9txxa+wKauazrzQX7lg1xbwmmfqJVCufFxjywovDl6GKNQfh9bmehanJwX
v3ypn2/xg3Yg8NJmGIh9hroGFS4zZWOHtjCbiqC+vQQhAgMBAAGjZjBkMA4GA1Ud
DwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgECMB0GA1UdDgQWBBQHBt/o2eRR
s6QRG8xaO8N3BDo9nDAfBgNVHSMEGDAWgBQHBt/o2eRRs6QRG8xaO8N3BDo9nDAN
BgkqhkiG9w0BAQsFAAOCAQEARo0WHVgTGDQsf2vja5hlPPEOYhZsx1r9xY3kwXHG
ZoRWMfo99YJ+p+3V3E+nrNB50XiXWsXuZ4oANOwVuqb8/woaKxkHS1ViI0hFWtxX
h0Gz1+MRh6jvS8j+/HtFZrVP9GccwqwXsSAS61qNqD70wRB1GsVMtpDpYMO8lHks
mmGmhEHpH6vEZRX2s/gsAYOBDB3BMIvHwxT8kuxeg2zTGtT3+jMohhDSLmibKlfX
QNREBd3kkgg3F+UdXLTFopOtHq+sUk8VU1gJEYWQkfqZM2qtqei9ZiQpaY4TPIEP
wYS5rHuBHFjFMa9+wJW+KuzsyLsMMa0UMAs8EVKCTO2jJQ==
-----END CERTIFICATE-----",
        kubernetes_ca_key       => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA6dwA74aX7qy6eBLQg9e+AEfBqa1O+nzIjlqAcKkw5HHgMjSc
zTs2dl8Ssf9JERQuSI7m8h23s/Xm6hA6uGAgKeUo1FnRm0GHLVgLDmXVNK902ZDT
w5Cz6LCod6NIHDUCnp1TpHHOn4d6GpToldWdcqie8GozH3y5yDPtBN/EgG2Pt0eT
VY1n2bvEqGdDu96TbmlCmLmMJkYfcZtw2QPQmAlKj0BSaNyLILWm6exj1Pfykz2/
bccWvsCmrms680F+5YNcW8Jpn6iVQrnxcY8sKLw5ehijUH4fW5noWpycF798qZ9v
8YN2IPDSZhiIfYa6BhUuM2Vjh7Ywm4qgvr0EIQIDAQABAoIBABhyYjqn5EwUDG4u
8VNHA1q+JZWaQ25WCxUuisy8Mxs+eERnUZj2vqvDJo4q9LVvWaNGJQhcaO7MHvaK
+ch6bAJVLV59gTbss7few1Ee/hnC2cFArZJ9FwGVLhdLn2crd3mjUrIXH5V3sSEE
Pggjy5DH5c2WHIAHJtix7O4cgks2da2WIS18fW6pU1n9YRPb4bAvtlAjZIO32aaY
nEpZV4t4Q+/Px6AWGqgouBqi9aLn1DZzG/s5IbwtoGgmIYKAE4FGRCIKkqWP/hmu
MYmW+SHZEzFHbU7WlPfcbvKdMus895cWFM4S71ckT35ppYHSyHLuJ3cOC6JOakna
4DNDwY0CgYEA8b0dYyyXKMKg/H0d2too/68vlVsFnwt/fxlJLsjPhYUNmRemMMGH
nVhlpEeDJbcBbLIWyCfd0jFNWy2d6+rOqHZu7hoi17kM1E93VEcZXlklEVBXqmnL
4NqYf59TqUYNX7Wv+8UIC90HU5b1ICrSNUVSE7DuVeR3l0T67UzP5scCgYEA96fj
6PQGippYjHuF+pDi64TheO7er9GiqmrYck4sE5drEYjNKH8sK9bCaulxanBqBPQf
XUWlOXFpaIIW+LEs2XKQP8KzAyeQvjwTv3B3a83wRnRQlp3VyYd+CNi5ejhYvPSe
yG4boOSHFbTmzTIl14f6ultlzSqyhqUGhnzNNdcCgYBcyUz1WxEuGP53y4JhFWm1
MkXeWxCeSmiGnWsEpRlaU4azo2srvazTDTH+S2CgYk0OrpCmBP9UhY3+mFTMT9VA
viy4AZosGSA+gb34wE2RdEARFDiB9ZfG18C/A6W2DGhnuzIwPiFnhFAimoe98BG9
Vr05R6lDmKz6iASUfu4x0wKBgHcnxDRVFMCjOm99Dx1bkJKYwJMa+vHE/2rXNYTp
r7NNaypok60kYvBEyA4Ae50msRvpCR4rYC+fLYQm8z58oIOO53CGEPM3miCtbyLw
zcSEtVJwrEWLc00fb7h57eOsMKXZXHw63fgve/8pptKbijGFL1FyoCxymqrFw7n5
WhLJAoGBAOTTimBJ1lOsH0tOfQ5XMLy7vBumWZ8jGTOiJI0XGHCx/N6TXvBm4QEX
cXTG+mVI2Vng7gye+Q1p4Y1JsvByiuneKtCyWxxLdy8EE0rgJPQGkPdSJfIq13wT
z2ssezv2fQeaPboQLcG27Z28udR3/e/bM3RpLGY7fsLaujyX8IXI
-----END RSA PRIVATE KEY-----",
        etcd_ca_key             => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA6pSGkQn0mBBo7r5TMcVzDWl+GchOE7KodSSJX4RdhsPIjwIQ
1tCXRaF/AgAySLrb4laRgGywr9dEX5X0NjG1fv/iW+nKOxETAyISdiN+14e7BnaQ
7Rwj1WqRpHgermKJnh7wuCWXmAn8sqKIx8cu2iaEk59GzWu0vFq7hGd+JfPVPGnx
CNXeu1mTmCqMw/QrWfM1Tu1u3DAr0YihfBN3ksX2FrhVZDhQAD8/p/bxsZmM/TyX
yh1IFZ5zUA/IfpKhSOC1BoxqxGskcAL/KMbtHIolTOrp7fpDBsG7XAydn8IEt6Y8
o9IIjSfnQ/fOOsPGapixcLCJM8RAeSCzaITmFwIDAQABAoIBAFI1AL+dZIlR3uQj
8NXVY0+E87snVi1TA/QhfL7rjTcoL4XmbG5LpWeyg+b4mKaiTWKRgeYmsPi+kOiK
jY3cd8Vs+S/Ky6NNhYMokp2yLMZte551OK7PmMM22JlxuxbT03SFVUjDa8/NWDBm
A1c3t3Sd4QI25EIjB7Cmf2aUOkIj+GDXq38/75UmWazYn8N6p+nPFjps3tMQ4vej
C95392+qf4HIy2W2upS0lTZIdGk5xyEm7kDkWncAq4wd0hc3pNUwGzS8VB62V5IL
V+Ti7uds7mFLKkVrWpKYWCrYl8OKmjRgpw5pNaFub3UHv/b4i5EqmvJ9Gs0zJnn7
nnYJHLkCgYEA/8VYATP1V96kaM6ZSzkdHqbKuYyYXo3LLxy8Bc3+uH3lMYhRznCo
TctWVnDVnakYtU8NE+PWjZSoecAfVgrd8qm3TFORqYMR6/EbjB0GwjcBqYy8nuQT
6CjYneWLE5g0IimozYv5XEz2oVrTdZ3+IcW3r1CcrkmrmHYODsHO0rsCgYEA6spS
e2WY8kHLnjTZMw0DtX8D4M6R6MVDYVpHafBcCj76keGmWX2ZNlhGjZUCVVz63qAb
ZDN4PKryq1x+j8zTDjn8fuHd17nbyWrRtuzSPP6R4csy1aYtSniUUNLSyjKv1CR9
mhWO8y3x7d78Ou68uFIaiKOr9L+bTqNyUbQO6lUCgYAPjF+dMxtnDBHSjTykZgRv
KJSKUxGwLc58PrLvZ2ZksMKOEEto0VBp6kKFXradrvnhi7yvyNnyIWdcf2FoSaDU
b5zE9w+TznP4c9/I1Lrkc5OWSwfsYNEU++avMpURy97fdMjeNfQiuEsF5A+WxtP8
GZjg/3WG4tOboRGZtA5uoQKBgBFdW1JTBkfMg/G0eOfkq4SN20ySGop7pGsb0TJN
m5EKbV/Cr5noxx8U0ksAXUbQ9KDoeH4lrFvYTNBNq/KYtHdV5I3ByLV+wnmYE+CS
jU4DieiILb9NZgYe+uErZnmb3BM1i7CMraDgogb0ufTl2UFMmTfH2xzj2umq/vZ5
+axtAoGBAIBw1XEFeSsxvaJHknOumR8AQKZcK3pdhrGq9u8qHX9ejTZSgajMnUSG
isHdQWQhcDoUJjzzSECms5eUZeXuILy+E6T4RYGq36qfaBzJHFu1r7OKbrYVehHm
5g60GFof8nq7RnrScB1Y0c3HwhHF4QK2PNNgC0mtQUgteHXodVNn
-----END RSA PRIVATE KEY-----",
        etcd_ca_crt             => "-----BEGIN CERTIFICATE-----
MIIDEjCCAfqgAwIBAgIUQi5KPtcwcswYS4sq9r4nkjdA0x4wDQYJKoZIhvcNAQEL
BQAwDzENMAsGA1UEAxMEZXRjZDAeFw0xOTAzMjcwNjQwMDBaFw0yNDAzMjUwNjQw
MDBaMA8xDTALBgNVBAMTBGV0Y2QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQDqlIaRCfSYEGjuvlMxxXMNaX4ZyE4Tsqh1JIlfhF2Gw8iPAhDW0JdFoX8C
ADJIutviVpGAbLCv10RflfQ2MbV+/+Jb6co7ERMDIhJ2I37Xh7sGdpDtHCPVapGk
eB6uYomeHvC4JZeYCfyyoojHxy7aJoSTn0bNa7S8WruEZ34l89U8afEI1d67WZOY
KozD9CtZ8zVO7W7cMCvRiKF8E3eSxfYWuFVkOFAAPz+n9vGxmYz9PJfKHUgVnnNQ
D8h+kqFI4LUGjGrEayRwAv8oxu0ciiVM6unt+kMGwbtcDJ2fwgS3pjyj0giNJ+dD
9846w8ZqmLFwsIkzxEB5ILNohOYXAgMBAAGjZjBkMA4GA1UdDwEB/wQEAwIBBjAS
BgNVHRMBAf8ECDAGAQH/AgECMB0GA1UdDgQWBBSV53H+cfzqtz1IZzW4xImvZaL9
FjAfBgNVHSMEGDAWgBSV53H+cfzqtz1IZzW4xImvZaL9FjANBgkqhkiG9w0BAQsF
AAOCAQEAkLzysgxWgro5DaFFTf+7hdq2uKqsR24pXMCLhwwoAmXGTjp+ff/6MySY
kbNXYPrbASyXteyIxlPwBoLd10I81lp6p4b0UJM/PrnhU2beRxbLW8Uneh10wTGC
CYZ+XpPM62M8QbWTqR3mh7dtN31DFwsJ/t1vPXVQ9OFI9M1glAaOkme+OnFoBeyn
dvNZsg670IE+YBUgl0VBKwZ50nBDzpHsvyJv186jLslbUMmVbMJAuAKr1YaWqB+w
FjoDzti4vlNCAYp57K4jEMFYpLtUXNqIaaIoW2Y3rAEvqVmpEE0Wtc+JC8BoDVjL
kb1gn3W9ajtYk39qpOn6JreDCdixKA==
-----END CERTIFICATE-----",
        etcdclient_key          => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAwJJ84jTLeG6MvMTQFkUUIxxSBP1EaqWklg6nDVgapHDXAxWY
BVAkuJOuJSsgdoZDPanJNYAfPHqlLtRW0+FYEGC/myamtksVu3sKYXOyW6XVMCk3
8XvwPBQxx0mku3+mizvR2hTx7K58xECvKIBABjp3i2Oqzmzn96crj8uWAPOk6x9c
0vxJYRfI9TF/n+V3U5q0IqaWM6qKIImgwbd+4k3Xq9Pdku/tHW8/Lx2ZJ/MNjq4f
xPrXE87fsuaVd0cuyGN2iQ5IxWcq5LjAIfMNqh9QwEX1w2adX5dgPyTPh4SQYId5
TKc1EhK+43ZlPUItnlEM4mX3eJy2Dn/rafdOXQIDAQABAoIBAAYnKBJaOX4ZmimV
6Egt4NzWVNCP/xWhQUcCJNhKTl+es2AH2pmg2+uB3HiXjiv7Uj6wJBuvgk/+YzTB
2BxhAN1VGgotC/qbH5Cj98rxVWuUOuGVD5KJsT1aL9T8R2UuSPX97VCYhrpXQOlM
X8xdfK42RAeSIa0C0c6Z6sxnZt2U3QWPJUW0r52zTcYWWcEP2/TaXml1lt80HMQE
b42/gfs6wSbhxkKOH7ioQYecXNoUngXp7ck94knE5UQJ0SYnFjk4NfS7SHhnt7Wd
51covOPY+hKWzt1K8I1zVlauY3fGGdjuiH/EtPuq3ngz2cOVsmZxrokEt15bABdm
eCVZ0QECgYEA/7EtG1UfMQpEkl27G0nOSYeGSi2Gf8JEu6GtAlAyXeD6y6Ys+EX5
Zh/oKxbfaAjOQVOtqgti4owRPGfu5n7hDBqQybUNBo3B8988QfXZ/PHPLhID5pvH
l2tMKOkfl+dSKuMXvEJFEKZTDMpDxKHaaiEvz6axGSyz2RCln+cc/70CgYEAwM3a
b9gXnYyBH3AU2kLSWPzxDNIpGA69lrtaWTmkdYPNQR/yEInMcCfUkJDMcGUjUWwn
X5N9mxUqj9zOdgDtjAZII8nUH0pzE6Ys6SMKoiF3wWtmUC59ygCIXnR+uDeZoAux
lKjr8/ZnKsEivQn9KPFC3JEhoIyov1tuRyHJoyECgYBqqLPSNP3f7RKRo7vLNExy
66+e/cKfRKB7TIPo9R8tfg3gKZ+UqUvRx/mHD/F9aj7vjUJiLoG/UwJVml1TlRW3
gNVo7rdSRovjePmf4jhehVgRNb6e0di+Vynb3vMo4HusHDLoexRoT5lROoZuXb3I
i7NwAW7au4UCRSlxvGyiWQKBgFkv4FfUcjgjAqf0RPEh8APSHf98SB4k03aifAzC
KV1i9tOlX2hfFf7breyhzrA/WLMVgLEpnPTcObAKyEa17yzSyxQjDMjcu5bfS+8c
kpKlQKxsbguxNeb3kB2BbgzxS1NJlX/bFCrqVJbmeJdRw5Xo5LD7Qb7u0jCSrtSg
wJGBAoGBAO0HX+2xbhNROVInHj9R79sqfx2C+KYhw8c0esjsNVWO/8um2+z9hGWk
40sRgZcHfWzEtARXIx31NlvEPssLrf10rFScCZJkN/khW+Vyv7SyH5drRKDouUqA
9CjdayNpy7G6fi/iCSltZK2qDd74RyLiZkvGhHruMN3qh6ZUZulU
-----END RSA PRIVATE KEY-----",
        etcdclient_crt          => "-----BEGIN CERTIFICATE-----
MIIDNDCCAhygAwIBAgIUVZ/KPRWEwxDbeMcntl/wV9jzIE8wDQYJKoZIhvcNAQEL
BQAwDzENMAsGA1UEAxMEZXRjZDAgFw0xOTAzMjcwNjQyMDBaGA8yMTE5MDMwMzA2
NDIwMFowETEPMA0GA1UEAxMGY2xpZW50MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAwJJ84jTLeG6MvMTQFkUUIxxSBP1EaqWklg6nDVgapHDXAxWYBVAk
uJOuJSsgdoZDPanJNYAfPHqlLtRW0+FYEGC/myamtksVu3sKYXOyW6XVMCk38Xvw
PBQxx0mku3+mizvR2hTx7K58xECvKIBABjp3i2Oqzmzn96crj8uWAPOk6x9c0vxJ
YRfI9TF/n+V3U5q0IqaWM6qKIImgwbd+4k3Xq9Pdku/tHW8/Lx2ZJ/MNjq4fxPrX
E87fsuaVd0cuyGN2iQ5IxWcq5LjAIfMNqh9QwEX1w2adX5dgPyTPh4SQYId5TKc1
EhK+43ZlPUItnlEM4mX3eJy2Dn/rafdOXQIDAQABo4GDMIGAMA4GA1UdDwEB/wQE
AwIFoDATBgNVHSUEDDAKBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQW
BBRt2mKLlZWjHWHQ5MjdLIl6Mc+jtDAfBgNVHSMEGDAWgBSV53H+cfzqtz1IZzW4
xImvZaL9FjALBgNVHREEBDACggAwDQYJKoZIhvcNAQELBQADggEBADtx6B22l1TM
FHNYghXtEYkB8dPIb/crQYUJWTzezR+GGrkDc6ugnfz+XceEpCx8LSe3eYJQR5DV
E1fFZSuzWPGm3NNR+M8TnNpa7fAqnFJ+FRMlEOC0h0CeooFiUYsXIgCKzBLmj6+t
wiQ8+WzIHwoC/29S+4MZcZ2ivZBBj7tXARpOU2i+T8hRVCrMwfR5bSj/WhvdMhlj
p9xSX4NKy2R/CixpyiRFQbUHssmzJAoU+yRxUlBUKDTC2U7xhWcTuTdMFxsBwqjP
0pZDEG8JupkbY4OZJ6+jEf8JgbV9moDOrO939Vh5zuiEQcKfp7XFVVGD7YOBZcN5
RIWwy9Ltx2w=
-----END CERTIFICATE-----",
        etcdserver_key          => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA4O0X8DEQgdi0KzFJzWV15Fpl5dJ4t52LSBRJPgk4sY6Goqcb
KpQudwlfQF0d8H0SpWCjzreUJ6QcOlhWklwBPOiZAlS/p9ACbPizCZMrUhqL126p
0U8DjZDhJEFH4WdbBP1U2XGKUlF5VkhhF1VS6d5SgWaPokTMCtgBrMUl2p3uTqF6
ssSG7/WIzAv847UbZB4vqQqWNJWOVXNSqu6jUTMT8zuFBZB5DpVWpjb0B5o/pHuy
Q+zGTQD+6w5yutJLFgoHPk0sYSlfPDFa3WjjonBAwJr8VR0jN69DMjZN+zbT8if2
moLwKE4QbseXaLNTRsQH167dd0egKXyANGD/jwIDAQABAoIBAGZHSdBd7zysNtlB
M2cj0OUCuj00ZNJR4GjpWJjOBqquvcgupqrI8QwOBfM1pIybwyPSewpf7g3MkU1y
qAMrtSBmQFWQBgqgCspUmM0sz9Eo4xgWaUAVZu8zxzz+Nlpn7jqpm7C48YYXKE60
4PmEQgy4nNncskm+cO4pZTGUAG+U8PBlEaykCGBxztLKYSYCkYlsbV3Xyls/nGEJ
Ke0fMJa9jALMSn3kwBzVyqFB4MMDBl8OGSHkd82d76IbjbXj9hjuHZT3a+UbjWYm
Egbu4IE1TG70dKdYCZnomZZQL27dCYhdaqhqeqEfVP1gh3g8e63eFIL28XfHiXhx
4cOeFmECgYEA7k8HOfLNY9//mAMtJDgr+YSjuDJcvzrlslTyLud9YpOF1vPtek6y
M/aeFx0tx7VOqbtheuAZzS/fk8ic7kJyTDvXx6ZELp9HXWW8CauKghpBHiHDYcoF
oU6/2l0G1TBqsPT8Wlb8jjkfZMpyaKe6FA4NbJSQF0ibjgGUHvuIJ1ECgYEA8Z+8
C/Bon5v2zk57hpGuZqfbPQV3R+ukXmW8lcNYzq3nWpi3ehYQZPM3nrli6EuzIUVD
jSWrA3kVYZ24sJYVRu0PDKt3ZSm8ZPj4WjKKH5eLmIvQy4BSfTG8hCaUpGVtegFh
SoUPLKKDmhpeKSwPl1IgIqDEltxTSbFDjAgqwN8CgYA7r3Nh4hvq7ck4K2N89Mye
u8e9dG+iPYAWAAyADt5qeARHZ+SMg3VCanwB0f8LS6+d9x5dBg+wQlM+0jnrupyh
10Md79iXzLC1BavoyBvypdy1TUOAFHcAhZarfC0f6/Zsx48EmVC71ja0qbep2ohS
SYq3LSZBjp/XGzIb6GebYQKBgQCGYK/Uc/+7xKGeW0eXr62uqevkJAYSmZrwZORc
5iedylnAqO5hl6PGgP2N6Mx5JKCbAEpxVWGmrNCXWYA9tTpgF7cm9LWSLYP5I/37
K+BlcYLRc/DLPLKjreWKGWrRgxc/o0TYjOfDix5ltgRoIXkKT0JP/9lVjXNEqLFI
T8J3QQKBgDru8zoXIRQjdn2qVL2VEMBD7v7QI09bs6OmxB2xuJbos9x9kFKaRgLM
N1nzplOdB/BrUSa2amQGpN/P4Qwj6icpZA9ZwQ6/s8r/GLVJbfOEoGjVOSBUh38p
LZDgQfHnEQ/bKaH1/Gge4XANWw1Enrp89R4hQb+0UCu/yWCDkD3J
-----END RSA PRIVATE KEY-----",
        etcdserver_crt          => "-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIUIviOB0nmzr6gftfrYw8SKJ8SYTIwDQYJKoZIhvcNAQEL
BQAwDzENMAsGA1UEAxMEZXRjZDAgFw0xOTAzMjcwNjUzMDBaGA8yMTE5MDMwMzA2
NTMwMFowETEPMA0GA1UEAxMGdm0tMDA4MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEA4O0X8DEQgdi0KzFJzWV15Fpl5dJ4t52LSBRJPgk4sY6GoqcbKpQu
dwlfQF0d8H0SpWCjzreUJ6QcOlhWklwBPOiZAlS/p9ACbPizCZMrUhqL126p0U8D
jZDhJEFH4WdbBP1U2XGKUlF5VkhhF1VS6d5SgWaPokTMCtgBrMUl2p3uTqF6ssSG
7/WIzAv847UbZB4vqQqWNJWOVXNSqu6jUTMT8zuFBZB5DpVWpjb0B5o/pHuyQ+zG
TQD+6w5yutJLFgoHPk0sYSlfPDFa3WjjonBAwJr8VR0jN69DMjZN+zbT8if2moLw
KE4QbseXaLNTRsQH167dd0egKXyANGD/jwIDAQABo4GZMIGWMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIw
ADAdBgNVHQ4EFgQUL4TxBW9vkGK4WsMjJS4NJVSbonwwHwYDVR0jBBgwFoAUledx
/nH86rc9SGc1uMSJr2Wi/RYwFwYDVR0RBBAwDoIGdm0tMDA4hwQKFRYJMA0GCSqG
SIb3DQEBCwUAA4IBAQAhgcvc8cJnrWyY6x6NwC2vgRf9PfuQrErWnwK1BKyJb04R
YxmuqhH1zbMAus6S8BP6aaBtLOYgqu4Z1Xk57j/YMwJe3xK4PwcyTLgTM3yMKbRg
a9a/T99eUxhx/QpLVZPIf/rc/hQWiR78FS1V89SQ1dd7vhyMkxdnofZWgad0m8Mw
CBW2ivYtH5Wv4G8i4c4wvzzZfjCM7y+B/l60+pd3lA8fIf1Mj8IhtcES9any2kCC
voivbfGuGqFWWo7ZDE/4jAqLo+Tv24sVGwu8PQkIbnI8wIZ8d+8WugUzttSIHqek
JxTEqOi47LpsIZd1iy/4YMt4CTr6esJ0ryRzoAAo
-----END CERTIFICATE-----",
        etcdpeer_crt            => "-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIUK2Bl+sMuG/faKk3HDUKFe7ngBk8wDQYJKoZIhvcNAQEL
BQAwDzENMAsGA1UEAxMEZXRjZDAgFw0xOTAzMjcwNjU0MDBaGA8yMTE5MDMwMzA2
NTQwMFowETEPMA0GA1UEAxMGdm0tMDA4MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAtl/iJcPdC6jGm6MpkJHAqKjJv3PARmDLvbOd9hg1EfBvh7tzOt6o
K7pIjpua0c0rGHYeMJNGRDWoAydOhN/18lrauf8B9Ek/Xu7Ibt5fEGjG2PQLO36F
9vYAIWGlZ4tEzkeqfDnJpZnZ0c7dpRI9/cP+AcdrZWz40rH4ShWQFrESdePYtDkX
3EcqTmAYVaZ62e+2/KGO3G9n2RvEffj5cDTQneR9antw9ymO33Hl8ezV50Z4S38g
Qiz6DaFvu+xcW3yNuBZlVLECnrX+3qJD3RM1sOZsldqEKtNbEqSQrg+MRruzL0YF
nJE7MK9eK9M6d/NHqleXd6577q+NBApiSwIDAQABo4GZMIGWMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIw
ADAdBgNVHQ4EFgQUiKMu0IyOcddWHg373KLI+1ygtHYwHwYDVR0jBBgwFoAUledx
/nH86rc9SGc1uMSJr2Wi/RYwFwYDVR0RBBAwDoIGdm0tMDA4hwQKFRYJMA0GCSqG
SIb3DQEBCwUAA4IBAQDYe91pRGxQnPZ1emDIUXt2zas/ew7WLqcJhdO0XL/vecnZ
d+KWaPOgYfaYrew8qPwNKVzCYE4bGyoL+nX2gitrpndARgndhGSSsff8YVJsGxme
/FO/VI9telbaIAufC9y5BSgL1BsdJ+P+Hd6Jvf+pmmHPu1dI0RPi9cIq2FP9o1Jn
kv0He9LJfofarPVYHkBQkGudTOfYKNOt8rql9x2wPINDXUELC0BPNnr5OxRIxsg6
OvRwzcl4b6edOm4G+6MnzwnlyYFwfrD3LZ/Q4VYxWbbCEDPbqy/1ULpTHkYsmUcb
FPv+yCs2cG+0FuIAYc3HchZoo6v+JWvr/p/4HC29
-----END CERTIFICATE-----",
        etcdpeer_key            => "-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAtl/iJcPdC6jGm6MpkJHAqKjJv3PARmDLvbOd9hg1EfBvh7tz
Ot6oK7pIjpua0c0rGHYeMJNGRDWoAydOhN/18lrauf8B9Ek/Xu7Ibt5fEGjG2PQL
O36F9vYAIWGlZ4tEzkeqfDnJpZnZ0c7dpRI9/cP+AcdrZWz40rH4ShWQFrESdePY
tDkX3EcqTmAYVaZ62e+2/KGO3G9n2RvEffj5cDTQneR9antw9ymO33Hl8ezV50Z4
S38gQiz6DaFvu+xcW3yNuBZlVLECnrX+3qJD3RM1sOZsldqEKtNbEqSQrg+MRruz
L0YFnJE7MK9eK9M6d/NHqleXd6577q+NBApiSwIDAQABAoIBAB1Ndqaeu8t9yLuF
Ec6avJvc0t2iGYi1UMcgLwc1iIFjYmgqpC8XS2oLOlE/izaegoghomQnpaib/mzT
Sfhri7bvBinQYV4Azt/P+gBmVlvqmdiODaf3gkrV59t1NwBWDi4esbPYDSBAghEF
7fLx5Wf6r7tVcVoQkkI4Oi6dHFOoxl49ETsI91vAuluDK/9qgXzVj4b6C0flfXPB
klQNSdWVHiNFvOgfWhZxvy5jeteSnlwodwwmOsWm8e68QvgPod89DX0aNSjoTSKz
RdI7G93if1bEceD8OIpnf4QWr3Tx7AkdRVfhrd7QVD7fI5SxKSpynjGokVSGd42e
PSn3wxECgYEA2/6DqFdISe1iyYrSAZL/8VxrW4l61szwR8dPqg8Sw/fqkl+uzGkH
MPauXSC6h/tkFKkvOo1i3qrD2lNtkdj6Xc6fif97iou7om2vInVX9+fuvsrSCNv6
8PO0s5bk9mI5sr2WpwEdAZckZSNDydnDRgjOBr5TyIV2/bUG9K3IgvcCgYEA1Dkm
7IgQfz5jecyDWupc/0Vt4nZ30NwVVmZT57qEbkn6UFI+1ASC1PBkG4Vfq324HYKU
nEykVFzgHU3RN8hVeoSGvVwhoZPHLtCY9dppzVG2NNaGimUrcD19CIt/VY1k7GBR
elT8MPxHd8q5dl922DGYFeJFkjz0iY1kdIufck0CgYBMgTM57LiX9PTgz+T+ZSea
wSAYojPU1UpOO/LpWfqVqfaqVpoMPg4hKfgzLLmRpowEX12sSBT1CH+5wj+dc86F
puB2diF5aeSjtO8t1Y71CHRPZ2spZ47aEnZp6fTP9hLIpQPqKgnzTqN6hIwDezZc
eZ1kXPX4Cun5iuXTW0gauwKBgHLBjMiuMq17oPLFoenRfQQUGP0yLkvkFi2oG4rc
kqvImPBB6PNglRZr/tXa4waqbpqWd6Gk198+cXmnEJDnZUFg1DMk1JK4hCZOacfX
mQqLOsmLjyja2AhTV379X5d1Y7Nlyekqd0xNvp+KIYtex7bT6nc66X/QMjMHH+Dd
dxSpAoGAXMkT97QFAiFwockVmwGJ7LTPMB2MN2R8tGLAqY5BVFDG3JZZ52fwqTkB
hJLQB0SAIG+LoIm63kRkfT/Rl1UFyqmRWXsMD9p1yhymG+OUedULWg4FBv0O0INT
s6Frp5Afig2LyVRtasuM7ZjGXqETmoKj5oUdOuHZ0rI2QW6gD5c=
-----END RSA PRIVATE KEY-----",
        sa_key                  => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAx2G2qQ4rBXriiAz5LMjivSZA3CZmk8iuPjOw8xtImZsH6akp
Mpjg5A7nKneTpz1534J4a/WB8hIuHzwFgBYcY5FcGrR0Wi0cUUfPPBoSPQ6YSYHm
wPDHlTZDU/+4VjhheEyUckMzFrM6LYNMp0k3xHzqMt9OjMrE+hFVdHXjTpqkknPT
beLfHdCcoFT8YgfdYZT8ZFP0QACpr1alMlZL+l5dNl5eb+A4tLoxihSSjfagGfsI
bwGOmc86iBnaXS32t+70PUVraxgjXQ4c/KJb5Q/EDMxThXvcIClKARyQ14lgCVgS
tmRJm3kpG+lRF77eV1Ffte5IE8kJcX/Ne13CqQIDAQABAoIBAHJDB2E+41zSnbwG
Y05NGdP4djc0MpkC6whuqzvHKQYOmKxJ63g5sLhB6iymNpIjYxK6PLTyD7RgwtnX
lfdftIlDJpuPSxbav129X4A8GLOxB4kozstHsblLTa534HZY/VLp4DDTXhXmRLMM
igNcrH8Ib1cULnn1QollIaoKXWgPqIgBaxdGa0/tKBNIe/77hP3zenzLhDVe7HFv
wPZbM8/8g6rxu/fcfzyHpfXFHXW8sqnkGphGuAL0YJ45QmfEQRaROwdLoPcnwmJz
IOI7jRB8Ysoj9CTewGMeRNSWIsBCKzFP45nJPMQCtU2zPhRNwCQqZAwL86OCsnan
g0N3/tkCgYEA7DcaPp0NM2a5rJL0d8rN9brqAg1vf2q7BTku6SLBJU7hv2/R2SPY
VORf9mFSBFNqXUcZin8Ygs9kwIj6+YRo81JoRIQ7DZtDxrYgOspnIPufCKM02NgP
ym6nVlPI0ym6Uaiu83lfmQBhIlWauF6ECoGGuKRS6inYIF0qjgDrpgsCgYEA2BTU
pVHXB60NlgIc66d3Kxtlyo54l1gJ2kd6IA17bQSOw2CD/ouDVggPuj41tmIs/wNP
nCTEagvZGuvRdNvVFHHm61HFkA4Rx0E8aO2XDFEMmDJgREP4eQNZ5pIVUskpl3eO
MS48OVCt0oF82jBPA4jxaFuB4G7B/QqdBbY27psCgYEAnj1foHhXQorbcYdUq/c5
OBeJ8ewMOGBIfvxKt7UnjJWmVzdSbdM8dcozmvqhFfLHe0tJCeWQhvjmNrDM6GBS
akZXQScP5FKR+clCGABFS+wkIoYqveUn1uV/xi4Eh6kZfuCwqrwxVW7So0yThFUU
wXD5zjGOtf1oIm4nNs/ZDPcCgYAsVSnDuWTKuGCfNFPGrZcvivF5e32WX4O1+xA9
X0bBeTvpLfYm1Wzey8yeQ4E1qDLfJ0jAGnMJ5uBmO5e/yBKRnUTpZt+HzLstDF9e
j9B7wG07FKrXlrJ18ZASVEp3r7oOz4Km6HuGrtza4aJCCcNMUF5nMM8WwuKeDf1l
XJssnQKBgG4jJ2jwrLgX+aZXvYm1x28j7Ln93PcS88/ibRdINdkbZw4/C0fq8sPh
I6ufqn8gcJm86AwC4ZZ5O9AqodxZsPgCoKw6DAZrQusEZ0xje9122atXzvJizd3G
XR4VPhV6HfG4s/MAFyeNFCPQbKwpwf41j6C5QMx44GIHc/XJFB0e
-----END RSA PRIVATE KEY-----",
        sa_pub                  => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAx2G2qQ4rBXriiAz5LMji
vSZA3CZmk8iuPjOw8xtImZsH6akpMpjg5A7nKneTpz1534J4a/WB8hIuHzwFgBYc
Y5FcGrR0Wi0cUUfPPBoSPQ6YSYHmwPDHlTZDU/+4VjhheEyUckMzFrM6LYNMp0k3
xHzqMt9OjMrE+hFVdHXjTpqkknPTbeLfHdCcoFT8YgfdYZT8ZFP0QACpr1alMlZL
+l5dNl5eb+A4tLoxihSSjfagGfsIbwGOmc86iBnaXS32t+70PUVraxgjXQ4c/KJb
5Q/EDMxThXvcIClKARyQ14lgCVgStmRJm3kpG+lRF77eV1Ffte5IE8kJcX/Ne13C
qQIDAQAB
-----END PUBLIC KEY-----"
    }

  } elsif($action_lower == 'uninstall') {

  } elsif($action_lower == 'addmaster') {

  } elsif($action_lower == 'removemaster') {

  } elsif($action_lower == 'addslave') {

  } elsif($action_lower == 'removeslave') {
  
  } 

}

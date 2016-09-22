class ssh_server {
  include packages

  define key {
    $key_name = $title

    file {
      "/etc/ssh/${key_name}":
        mode    => '0600',
        require => Package['openssh-server'],
        source  => "puppet:///modules/ssh_server/${key_name}";

      "/etc/ssh/${key_name}.pub":
        mode    => '0644',
        require => Package['openssh-server'],
        source  => "puppet:///modules/ssh_server/${key_name}.pub";
    }
  }

  ::ssh_server::key {
    [ 'ssh_host_dsa_key', 'ssh_host_ecdsa_key', 'ssh_host_rsa_key', ]:
      ;
  }

  Package <| title == openssh-server |>
}

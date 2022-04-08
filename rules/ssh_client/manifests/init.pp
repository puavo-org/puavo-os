class ssh_client {
  include ::packages

  file {
    '/etc/ssh/ssh_config.d/no_stricthostkeychecking.conf':
      require => Package['openssh-server'],
      source  => 'puppet:///modules/ssh_client/no_stricthostkeychecking.conf';
  }

  Package <| title == 'openssh-server' |>
}

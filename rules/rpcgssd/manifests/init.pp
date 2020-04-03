class rpcgssd {
  # Startup rpc.gssd with "-n"-flag and without /etc/krb5.keytab dependency
  # so it can be used on netboot devices.
  include ::packages

  file {
    '/etc/systemd/system/rpc-gssd.service.d':
     ensure  => directory,
     require => Package['systemd'];

    '/etc/systemd/system/rpc-gssd.service.d/override.conf':
     require => Package['systemd'],
     source  => 'puppet:///modules/rpcgssd/rpc-gssd.service.d_override.conf';
  }

  Package <| title == systemd |>
}

class rpcgssd {
  # Startup rpc.gssd with "-n"-flag and without /etc/krb5.keytab dependency
  # so it can be used on netboot devices.

  file {
    '/etc/systemd/system/rpc-gssd.service.d':
     ensure => directory;

    '/etc/systemd/system/rpc-gssd.service.d/override.conf':
     source => 'puppet:///modules/rpcgssd/rpc-gssd.service.d_override.conf';
  }
}

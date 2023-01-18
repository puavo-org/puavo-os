class accountsservice {
  # Use some overrides with StateDirectory.  systemd does not like if StateDirectory
  # is a symbolic link (as we link it under /state on laptops), so we must change
  # the configuration a bit.

  file {
    '/etc/systemd/system/accounts-daemon.service.d':
      ensure => directory;

    '/etc/systemd/system/accounts-daemon.service.d/accounts-daemon_override.conf':
      source  => 'puppet:///modules/accountsservice/accounts-daemon_override.conf';
  }
}

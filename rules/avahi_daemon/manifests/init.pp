class avahi_daemon {
  file {
    '/etc/avahi/avahi-daemon.conf':
      require => Package['avahi-daemon'],
      source  => 'puppet:///modules/avahi_daemon/avahi-daemon.conf';
  }
}

class bootserver_inetd {
  file {
    '/etc/inetd.conf':
      content => template('bootserver_inetd/inetd.conf'),
      notify  => Service['openbsd-inetd'];
  }

  service {
    'openbsd-inetd':
      ensure => running;
  }
}

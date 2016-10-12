class bootserver_cups {
  include apparmor,
          puavo
  require bootserver_nss

  file {
    '/etc/apparmor.d/local/usr.sbin.cupsd':
      content => template('bootserver_cups/apparmor_usr.sbin.cupsd'),
      notify  => Service['apparmor'];

    '/etc/cups/cupsd.conf':
      content => template('bootserver_cups/cupsd.conf'),
      notify  => Service['cups'];

    '/etc/cups/cups-files.conf':
      content => template('bootserver_cups/cups-files.conf'),
      notify  => Service['cups'];

    '/etc/init/cups-watchdog.conf':
      content => template('bootserver_cups/cups-watchdog.upstart'),
      mode    => 0644,
      notify  => Service['cups-watchdog'],
      require => File['/usr/local/lib/cups-watchdog'];

    '/etc/init.d/cups-watchdog':
      before  => Service['cups-watchdog'],
      ensure  => link,
      require => File['/etc/init/cups-watchdog.conf'],
      target  => '/lib/init/upstart-job';

    '/usr/local/lib/cups-watchdog':
      content => template('bootserver_cups/cups-watchdog'),
      mode    => 0755,
      notify  => Service['cups-watchdog'];
  }

  service {
    [ 'cups'
    , 'cups-watchdog' ]:
      enable => true,
      ensure => running;
  }
}

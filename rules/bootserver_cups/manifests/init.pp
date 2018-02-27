class bootserver_cups {
  include ::apparmor
  include ::puavo
  require ::bootserver_nss

  file {
    '/etc/apparmor.d/local/usr.sbin.cupsd':
      content => template('bootserver_cups/apparmor_usr.sbin.cupsd');

    '/etc/cups/cupsd.conf':
      content => template('bootserver_cups/cupsd.conf');

    '/etc/cups/cups-files.conf':
      content => template('bootserver_cups/cups-files.conf');

    '/etc/init/cups-watchdog.conf':
      content => template('bootserver_cups/cups-watchdog.upstart'),
      mode    => '0644',
      require => File['/usr/local/lib/cups-watchdog'];

    '/etc/init.d/cups-watchdog':
      ensure  => link,
      require => File['/etc/init/cups-watchdog.conf'],
      target  => '/lib/init/upstart-job';

    '/usr/local/lib/cups-watchdog':
      content => template('bootserver_cups/cups-watchdog'),
      mode    => '0755';
  }
}

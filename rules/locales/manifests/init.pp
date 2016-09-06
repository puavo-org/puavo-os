class locales {
  exec {
    '/usr/sbin/locale-gen':
      refreshonly => true;
  }

  file {
    '/etc/locale.gen':
      notify => Exec['/usr/sbin/locale-gen'],
      source => 'puppet:///modules/locales/locale.gen';
  }
}

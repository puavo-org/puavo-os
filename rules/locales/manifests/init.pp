class locales {
  exec {
    '/usr/sbin/locale-gen':
      unless => 'test /usr/lib/locale/locale-archive -nt /etc/locale.gen';
  }

  file {
    '/etc/locale.gen':
      before => Exec['/usr/sbin/locale-gen'],
      source => 'puppet:///modules/locales/locale.gen';
  }
}

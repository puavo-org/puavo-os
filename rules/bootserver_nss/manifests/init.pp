class bootserver_nss {
  include ::puavo

  ## For some unknown reason, nslcd seems to occasionally spawn twice
  ## causing ldap NSS service to fail. In normal condition, there's two
  ## nslcd processes: a parent and a child. In case of a spawn error,
  ## there's two of those nslcd process trees.
  exec {
    'kill redundant nslcd instances':
      command => '/usr/bin/pkill -x nslcd',
      notify  => Service['nslcd'],
      onlyif  => '/usr/bin/test "$(/usr/bin/pgrep -x -c nslcd)" -ne 2';
  }

  file {
    '/etc/nsswitch.conf':
      content => template('bootserver_nss/nsswitch.conf'),
      notify  => Service['nscd'];

    '/etc/nscd.conf':
      content => template('bootserver_nss/nscd.conf'),
      notify  => Service['nscd'];

    '/etc/nslcd.conf':
      content => template('bootserver_nss/nslcd.conf'),
      mode    => 640,
      group   => nslcd,
      notify  => Service['nslcd'];
  }

  package {
    'sssd':
      ensure  => purged,
      require => [ File['/etc/nsswitch.conf'], Service['nslcd'], ];
  }

  service {
    'nscd':
      ensure  => running,
      require => File['/etc/nscd.conf'];

    'nslcd':
      ensure  => running,
      require => File['/etc/nslcd.conf'];
  }
}

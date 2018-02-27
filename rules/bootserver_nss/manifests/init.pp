class bootserver_nss {
  include ::puavo

  ## For some unknown reason, nslcd seems to occasionally spawn twice
  ## causing ldap NSS service to fail. In normal condition, there's two
  ## nslcd processes: a parent and a child. In case of a spawn error,
  ## there's two of those nslcd process trees.
  exec {
    'kill redundant nslcd instances':
      command => '/usr/bin/pkill -x nslcd',
      onlyif  => '/usr/bin/test "$(/usr/bin/pgrep -x -c nslcd)" -gt 2';
  }

  file {
    '/etc/nsswitch.conf':
      content => template('bootserver_nss/nsswitch.conf');

    '/etc/nscd.conf':
      content => template('bootserver_nss/nscd.conf');

    '/etc/nslcd.conf':
      content => template('bootserver_nss/nslcd.conf'),
      mode    => '0640',
      group   => nslcd;
  }

  package {
    'sssd':
      ensure  => purged,
      require => File['/etc/nsswitch.conf'];
  }
}

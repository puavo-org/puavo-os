class keyutils {
  include ::packages

  dpkg::divert {
    '/etc/request-key.d/cifs.idmap.conf':
      before => File['/etc/request-key.d/cifs.idmap.conf'],
      dest   => '/etc/request-key.d/cifs.idmap.conf.distrib';

    '/etc/request-key.d/cifs.spnego.conf':
      before => File['/etc/request-key.d/cifs.spnego.conf'],
      dest   => '/etc/request-key.d/cifs.spnego.conf.distrib';
  }

  file {
    '/etc/request-key.d/cifs.idmap.conf':
      content => template('keyutils/cifs.idmap.conf'),
      require => Package['keyutils'];

    '/etc/request-key.d/cifs.spnego.conf':
      content => template('keyutils/cifs.spnego.conf'),
      require => Package['keyutils'];
  }

  Package <| title == keyutils |>
}

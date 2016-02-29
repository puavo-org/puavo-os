class console {
  include packages

  file {
    '/etc/init/ttyS0.conf':
      content => template('console/ttyS0.conf');

    '/usr/share/puavo-conf/parameters/puavo-rules-console.json':
      content => template('console/puavo-conf-parameters.json'),
      require => Package['puavo-conf'];
  }

  Package <| title == puavo-conf |>
}

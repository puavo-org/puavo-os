class console {
  include initramfs

  file {
    '/etc/default/console-setup':
      content => template('console/console-setup.default'),
      require => Package['console-setup'];

    '/etc/init/ttyS0.conf':
      content => template('console/ttyS0.conf');

    '/usr/share/puavo-conf/definitions/puavo-rules-console.json':
      content => template('console/puavo-conf-parameters.json'),
      notify  => Exec['initramfs::update'];
  }

  Package <| title == console-setup |>
}

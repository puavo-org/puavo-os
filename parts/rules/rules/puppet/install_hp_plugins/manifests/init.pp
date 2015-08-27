class install_hp_plugins {
  include packages

  exec {
    'puavo-download-hp-plugins':
      command => '/usr/local/sbin/puavo-download-hp-plugins \
                    && /bin/touch /tmp/.puavo-download-hp-plugins.done',
      creates => '/tmp/.puavo-download-hp-plugins.done',
      require => File['/usr/local/sbin/puavo-download-hp-plugins'];
  }

  file {
    '/usr/local/sbin/puavo-download-hp-plugins':
      mode    => 755,
      require => [ Package['expect'], Package['hplip'] ],
      source  => 'puppet:///modules/install_hp_plugins/puavo-download-hp-plugins';
  }

  Package <| title == expect or title == hplip |>
}

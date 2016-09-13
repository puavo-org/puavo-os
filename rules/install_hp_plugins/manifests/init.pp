class install_hp_plugins {
  include packages

  exec {
    'puavo-download-hp-plugins':
      command => '/usr/local/sbin/puavo-download-hp-plugins',
      require => File['/usr/local/sbin/puavo-download-hp-plugins'],
      unless  => '/bin/grep -qx "installed = 1" /var/lib/hp/hplip.state';
  }

  file {
    '/usr/local/sbin/puavo-download-hp-plugins':
      mode    => '0755',
      require => [ Package['expect'], Package['hplip'] ],
      source  => 'puppet:///modules/install_hp_plugins/puavo-download-hp-plugins';
  }

  Package <| title == expect or title == hplip |>
}

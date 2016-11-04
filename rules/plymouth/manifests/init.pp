class plymouth {
  include ::packages

  exec {
    'plymouth::set-default-theme':
      command     => '/usr/sbin/plymouth-set-default-theme -R kites',
      refreshonly => true,
      require     => Package['plymouth'];
  }

  file {
    '/usr/share/plymouth/themes/kites':
      notify  => Exec['plymouth::set-default-theme'],
      recurse => true,
      require => Package['plymouth'],
      source  => 'puppet:///modules/plymouth/theme/kites';
  }

  Package <| title == plymouth |>
}

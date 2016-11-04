class plymouth {
  include ::packages

  $default_theme = 'kites'

  define install_theme () {
    $theme_name = $title

    file {
      "/usr/share/plymouth/themes/${theme_name}":
        notify  => Exec['plymouth::set-default-theme'],
        recurse => true,
        require => Package['plymouth'],
        source  => "puppet:///modules/plymouth/theme/${theme_name}";
    }

  }

  exec {
    'plymouth::set-default-theme':
      command     => "/usr/sbin/plymouth-set-default-theme -R ${default_theme}",
      refreshonly => true,
      require     => Package['plymouth'];
  }

  ::plymouth::install_theme {
    'kites': ;
  }

  Package <| title == plymouth |>
}

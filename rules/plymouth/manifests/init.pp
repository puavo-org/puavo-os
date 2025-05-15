class plymouth {
  include ::packages

  # This hack is needed to so that /usr/sbin/plymouth-set-default-theme
  # does not trigger an error (update-initramfs is presumed, but we
  # use Dracut, and besides we handled initrd-updates elsewhere).
  file {
    '/usr/sbin/update-initramfs':
      ensure => link,
      target => '/usr/bin/true';
  }

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

  define set_default_theme () {
    $default_theme = $title

    exec {
      'plymouth::set-default-theme':
        command  => "/usr/sbin/plymouth-set-default-theme -R ${default_theme}",
        onlyif   => "/usr/bin/test \"$(/usr/sbin/plymouth-set-default-theme)\" != \"${default_theme}\"",
        require  => [ File['/usr/sbin/update-initramfs'], Package['plymouth'] ];
    }
  }

  Package <| title == plymouth |>
}

class plymouth {
  include ::packages

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
        require  => Package['plymouth'];
    }
  }

  file {
    '/usr/share/initramfs-tools/hooks/puavo-os-plymouth':
      mode    => '0755',
      require => Package['initramfs-tools-core'],
      source  => 'puppet:///modules/plymouth/puavo-os-plymouth-initramfs-hook';
  }

  Package <|
       title == 'initramfs-tools-core'
    or title == 'plymouth'
  |>
}

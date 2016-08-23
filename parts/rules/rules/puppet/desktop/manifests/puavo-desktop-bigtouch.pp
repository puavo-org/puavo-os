class desktop::puavo-desktop-bigtouch {
  include desktop::dconf,
          dpkg,
          gnome_shell_extensions,
          initramfs,
          packages

  dpkg::simpledivert {
    '/etc/xdg/autostart/onboard-autostart.desktop':
      before => File['/etc/xdg/autostart/onboard-autostart.desktop'];
  }

  file {
    '/etc/dconf/db/puavo-desktop-bigtouch.d':
      ensure => directory;

    '/etc/dconf/db/puavo-desktop-bigtouch.d/profile':
      content => template('desktop/puavo-desktop-bigtouch/profile'),
      notify  => Exec['update dconf'];

    '/etc/xdg/autostart/onboard-autostart.desktop':
      content => template('desktop/puavo-desktop-bigtouch/onboard-autostart.desktop'),
      require => Package['onboard'];

    '/usr/local/lib/puavo-onboard':
      content => template('desktop/puavo-desktop-bigtouch/puavo-onboard'),
      mode    => 0755,
      require => Package['onboard'];

    '/usr/share/puavo-conf/definitions/puavo-onboard.json':
      content => template('desktop/puavo-desktop-bigtouch/puavo-conf-parameters.json'),
      notify  => Exec['initramfs::update'],
      require => Package['puavo-conf'];
  }

  Package <| title == onboard
          or title == puavo-conf |>
}

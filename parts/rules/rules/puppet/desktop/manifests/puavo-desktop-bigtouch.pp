class desktop::puavo-desktop-bigtouch {
  include desktop::dconf,
          dpkg,
          gnome_shell_extensions,
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

    '/usr/local/lib/onboard-toggle':
      content => template('desktop/puavo-desktop-bigtouch/onboard-toggle'),
      mode    => 0755;

    '/usr/local/lib/overview-toggle':
      content => template('desktop/puavo-desktop-bigtouch/overview-toggle'),
      mode    => 0755;

    '/usr/share/applications/onboard-toggle.desktop':
      content => template('desktop/puavo-desktop-bigtouch/onboard-toggle.desktop');

    '/usr/share/applications/overview-toggle.desktop':
      content => template('desktop/puavo-desktop-bigtouch/overview-toggle.desktop');

    '/usr/share/puavo-conf/parameters/puavo-onboard.json':
      content => template('desktop/puavo-desktop-bigtouch/puavo-conf-parameters.json');
  }

  Package <| title == onboard |>
}

class desktop::puavo_desktop_bigtouch {
  include ::desktop::dconf
  include ::dpkg
  include ::gnome_shell_extensions
  include ::packages
  include ::puavo_conf

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
      mode    => '0755',
      require => Package['onboard'];

  }

  ::puavo_conf::definition {
    'puavo-onboard.json':
      source => 'puppet:///modules/desktop/puavo-onboard.json';
  }

  Package <| title == onboard |>
}

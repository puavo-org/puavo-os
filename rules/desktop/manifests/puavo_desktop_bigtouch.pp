class desktop::puavo_desktop_bigtouch {
  include ::bigtouch
  include ::dconf
  include ::dpkg
  include ::packages
  include ::puavo_conf

  dpkg::simpledivert {
    '/etc/xdg/autostart/onboard-autostart.desktop':
      before => File['/etc/xdg/autostart/onboard-autostart.desktop'];
  }

  ::dconf::configfile {
    'dconf puavo-desktop-bigtouch':
      content => template('desktop/puavo-desktop-bigtouch/profile'),
      dbname  => 'puavo-desktop-bigtouch',
      subpath => 'profile';
  }

  file {
    '/etc/dconf/db/puavo-desktop-bigtouch.d':
      ensure => directory;

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

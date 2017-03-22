class gdm {
  include ::art
  include ::packages
  include ::puavo_conf

  exec {
    '/usr/sbin/dpkg-reconfigure gdm3':
      refreshonly => true;
  }

  file {
    '/etc/gdm3/background.img':
      ensure  => link,
      require => [ Package['gdm3'], Package['ubuntu-wallpapers-saucy'], ],
      target  => '/usr/share/backgrounds/Grass_by_Jeremy_Hill.jpg';

    '/etc/gdm3/daemon.conf':
      notify  => Exec['/usr/sbin/dpkg-reconfigure gdm3'],
      require => Package['gdm3'],
      source  => 'puppet:///modules/gdm/daemon.conf';

    '/usr/share/gdm/greeter/autostart/puavo-remote-assistance-applet.desktop':
      ensure  => link,
      require => [ Package['gdm3'], Package['puavo-ltsp-client'], ],
      target  => '/etc/xdg/autostart/puavo-remote-assistance-applet.desktop';
  }

  ::puavo_conf::script {
    'setup_gdm':
      require => ::Puavo_conf::Definition['puavo-art.json'],
      source  => 'puppet:///modules/gdm/setup_gdm';

    'setup_loginscreen_background':
      require => ::Puavo_conf::Definition['puavo-art.json'],
      source  => 'puppet:///modules/gdm/setup_loginscreen_background';

    'setup_xsessions':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/gdm/setup_xsessions';
  }

  Package <|
       title == gdm3
    or title == puavo-ltsp-client
    or title == ubuntu-wallpapers-saucy
  |>
}

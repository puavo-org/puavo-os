class themes {
  include ::dpkg
  include ::gdm
  include ::puavo_conf

  ::dpkg::simpledivert {
    '/usr/share/themes/Arc/gnome-shell/gnome-shell.css':
      before => File['/usr/share/themes/Arc/gnome-shell/gnome-shell.css'];
  }

  file {
    '/usr/share/themes':
      ensure => directory;

    '/usr/share/themes/Arc/gnome-shell/gnome-shell.css':
      source => 'puppet:///modules/themes/Arc/gnome-shell/gnome-shell.css';

    '/usr/share/themes/Geos-puavo-dark-panel':
      recurse => true,
      source  => 'puppet:///modules/themes/Geos-puavo-dark-panel';

    '/usr/share/themes/Minwaita-Vanilla-Puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Minwaita-Vanilla-Puavo';

    '/usr/share/themes/Puavo':
      recurse => true,
      require => File['/etc/gdm3/background.img'],
      source  => 'puppet:///modules/themes/Puavo';
  }

  ::puavo_conf::definition {
    'puavo-themes.json':
      source => 'puppet:///modules/themes/puavo-themes.json';
  }

  Package <| title == arc-theme |>
}

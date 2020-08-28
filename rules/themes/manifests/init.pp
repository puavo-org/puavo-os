class themes {
  include ::dpkg
  include ::gdm
  include ::puavo_conf
  include ::puavo_pkg::packages

  ::dpkg::simpledivert {
    '/usr/share/themes/Arc/gnome-shell/gnome-shell.css':
      before => File['/usr/share/themes/Arc/gnome-shell/gnome-shell.css'];
  }

  define iconlink ($target) {
    $iconpath = $title

    file {
      "/usr/share/icons/hicolor/${iconpath}":
        ensure  => link,
        notify  => Exec['refresh hicolor icon cache'],
        require => Puavo_pkg::Install['tela-icon-theme'],
        target  => "/usr/share/icons/${target}";
    }
  }

  exec {
    'refresh hicolor icon cache':
      cwd         => '/usr/share/icons',
      command     => '/usr/bin/gtk-update-icon-cache hicolor',
      refreshonly => true;
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

  ::themes::iconlink {
    'scalable/apps/puavo-multitasking-view.svg':
      target => 'Tela/scalable/apps/deepin-multitasking-view.svg';

    'scalable/places/puavo-base-user-desktop.svg':
      target => 'Tela/scalable/places/user-desktop.svg';

    'scalable/places/puavo-hover-user-desktop.svg':
      target => 'Tela/scalable/places/purple-user-desktop.svg';
  }

  ::puavo_conf::definition {
    'puavo-themes.json':
      source => 'puppet:///modules/themes/puavo-themes.json';
  }

  Package <| title == arc-theme |>

  Puavo_pkg::Install <| title == tela-icon-theme |>
}

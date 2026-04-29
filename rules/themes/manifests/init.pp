class themes {
  include ::gdm
  include ::puavo_conf
  include ::puavo_pkg::packages
  include ::themes::yaru_theme_fix

  file {
    '/usr/share/themes/Adwaita':
      ensure => directory;

    '/usr/share/themes/Adwaita/gnome-shell':
      ensure => directory;
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
    '/usr/share/themes/Adwaita/gnome-shell/gnome-shell.css':
      require => File['/usr/share/themes/Adwaita/gnome-shell'],
      source  => 'puppet:///modules/themes/Adwaita/gnome-shell/gnome-shell.css';
  }

  file {
    '/etc/xdg/qt5ct':
      ensure => directory;

    '/etc/xdg/qt5ct/qt5ct.conf':
      require => Package['qt5ct'],
      source  => 'puppet:///modules/themes/qt5ct.conf';
  }

  file {
    '/etc/xdg/Kvantum':
      ensure => directory;

    '/etc/xdg/Kvantum/kvantum.kvconfig':
      require => Package['qt-style-kvantum'],
      source  => 'puppet:///modules/themes/kvantum.kvconfig';
  }

  ::themes::iconlink {
    'scalable/apps/puavo-multitasking-view.svg':
      target => 'Tela/scalable/apps/deepin-multitasking-view.svg';

    'scalable/places/puavo-base-user-desktop.svg':
      target => 'Tela/scalable/places/user-desktop.svg';

    'scalable/places/puavo-hover-user-desktop.svg':
      target => 'Tela/scalable/places/purple-user-desktop.svg';
  }

  Package <|
       title == qt5ct
    or title == qt-style-kvantum
  |>

  Puavo_pkg::Install <| title == tela-icon-theme |>
}

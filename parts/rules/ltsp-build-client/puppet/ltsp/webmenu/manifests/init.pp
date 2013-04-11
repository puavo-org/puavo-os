class webmenu {
  include dpkg,
          packages

  dpkg::divert {
    '/usr/share/applications/webmenu-spawn.desktop':
      dest => '/usr/share/applications/webmenu-spawn.desktop.dist';

    '/usr/share/applications/webmenu-spawn-logout.desktop':
      dest => '/usr/share/applications/webmenu-spawn-logout.desktop.dist';
  }

  File { require => [ Package['liitu-themes']
		    , Package['webmenu'] ], }
  file {
    '/etc/webmenu':
      ensure => directory;

# XXX remove for now... we must figure out where we want this from
#   '/etc/webmenu/config.json':
#     content => template('webmenu/config.json');
#
#   '/etc/webmenu/menu.json':
#     content => template('webmenu/menu.json');

    '/etc/xdg/autostart/webmenu.desktop':
      content => template('webmenu/webmenu.desktop');

    '/usr/share/applications/webmenu-spawn.desktop':
      content => template('webmenu/webmenu-spawn.desktop'),
      require => Dpkg::Divert['/usr/share/applications/webmenu-spawn.desktop'];

    '/usr/share/applications/webmenu-spawn-logout.desktop':
      content => template('webmenu/webmenu-spawn-logout.desktop'),
      require => Dpkg::Divert['/usr/share/applications/webmenu-spawn-logout.desktop'];

  }

  Package <| (title == liitu-themes)
          or (title == webmenu)      |>
}

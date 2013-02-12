class webmenu {
  include packages

  File { require => [ Package['liitu-themes']
		    , Package['webmenu'] ], }
  file {
    '/etc/webmenu':
      ensure => directory;

    '/etc/webmenu/config.json':
      content => template('webmenu/config.json');

    '/etc/xdg/autostart/webmenu.desktop':
      content => template('webmenu/webmenu.desktop');

    '/usr/share/applications/webmenu-spawn.desktop':
      content => template('webmenu/webmenu-spawn.desktop');
  }

  Package <| (title == liitu-themes)
          or (title == webmenu)      |>
}

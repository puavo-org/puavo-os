class webmenu {
  include packages

  # XXX these might be unnecessary once we get these into webmenu-package
  # XXX itself
  file {
    '/etc/xdg/autostart/webmenu.desktop':
      content => template('webmenu/webmenu.desktop'),
      require => Package['webmenu'];

    '/usr/share/applications/webmenu-spawn.desktop':
      content => template('webmenu/webmenu-spawn.desktop'),
      require => Package['webmenu'];
  }

  Package <| (title == liitu-themes)
          or (title == webmenu)      |>
}

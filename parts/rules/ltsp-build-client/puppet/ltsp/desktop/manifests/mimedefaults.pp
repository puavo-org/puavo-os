class desktop::mimedefaults {
  require packages

  file {
    '/usr/share/applications/defaults.list':
       content => template('desktop/defaults.list');
  }

  file {
    '/etc/gnome/defaults.list':
       content => template('desktop/defaults.list');
  }

  Package <| title == desktop-file-utils |>
}

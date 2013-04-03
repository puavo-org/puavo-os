class desktop::mimedefaults {
  require packages

  file {
    '/etc/gnome/defaults.list':
       content => template('desktop/defaults.list');
  }

  Package <| title == desktop-file-utils |>
}

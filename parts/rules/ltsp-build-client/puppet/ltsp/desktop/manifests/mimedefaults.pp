class desktop::mimedefaults {
  file {
    '/etc/gnome/defaults.list':
       content => template('desktop/defaults.list');
  }
}

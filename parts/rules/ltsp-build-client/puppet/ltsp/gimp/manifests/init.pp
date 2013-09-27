class gimp {
  include packages
  
  file {
    '/usr/local/bin/start_gimp':
      content => template('gimp/start_gimp'),
      mode    => 755;

    '/usr/share/applications/gimp.desktop':
      content => template('gimp/gimp.desktop'),
      require => [ Package['gimp'], ];
  }

    Package <| (title == gimp) |>
}

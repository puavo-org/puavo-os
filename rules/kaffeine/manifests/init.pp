class kaffeine {
  include packages
  
  file {
    '/usr/share/applications/kde4/kaffeine-dvd.desktop':
      content => template('kaffeine/kaffeine-dvd.desktop'),
      require => [ Package['kaffeine'], ];
  }

    Package <| (title == kaffeine) |>
}

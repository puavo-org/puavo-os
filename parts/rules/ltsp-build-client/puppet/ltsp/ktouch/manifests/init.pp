class ktouch {
  include packages

  file {
    '/usr/share/kde4/apps/ktouch/keyboard/finnish/fi.junior.ktouch.xml':
      content => template('ktouch/fi.junior.ktouch.xml'),
      require => Package['ktouch'];
  }

  file {
    '/usr/share/kde4/apps/ktouch/keyboard/english/en.junior.hard.ktouch.xml':
      content => template('ktouch/en.junior.hard.ktouch.xml'),
      require => Package['ktouch'];
  }

  file {
    '/usr/share/kde4/apps/ktouch/keyboard/english/en.junior.easy.ktouch.xml':
      content => template('ktouch/en.junior.easy.ktouch.xml'),
      require => Package['ktouch'];
  }

  Package <| title == ktouch |>
}

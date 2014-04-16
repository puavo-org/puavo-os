class ktouch {
  include packages

  File {
    require => Package['ktouch']
  }

  $ktouch_prefix = '/usr/share/kde4/apps/ktouch/Lecture'

  file {
    "${ktouch_prefix}/Finnish/fi.junior-remake.ktouch.xml":
      content => template('ktouch/fi.junior-remake.ktouch.xml');

    "${ktouch_prefix}/English/en.junior.hard.ktouch.xml":
      content => template('ktouch/en.junior.hard.ktouch.xml');

    "${ktouch_prefix}/English/en.junior.easy.ktouch.xml":
      content => template('ktouch/en.junior.easy.ktouch.xml');
  }

  Package <| title == ktouch |>
}

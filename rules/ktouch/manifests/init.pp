class ktouch {
  include ::dpkg
  include ::packages

  $ktouch_dir = '/usr/share/kde4/apps/ktouch'

  dpkg::simpledivert {
    [ "${ktouch_dir}/courses/fi.xml", "${ktouch_dir}/data.xml", ]: ;
  }

  file {
    "${ktouch_dir}/data.xml":
      require => [ Dpkg::Simpledivert["${ktouch_dir}/data.xml"]
                 , Package['ktouch'] ],
      source  => 'puppet:///modules/ktouch/data.xml';

    "${ktouch_dir}/courses/en.junior.easy.ktouch.xml":
      require => Package['ktouch'],
      source  => 'puppet:///modules/ktouch/en.junior.easy.ktouch.xml';

    "${ktouch_dir}/courses/en.junior.hard.ktouch.xml":
      require => Package['ktouch'],
      source  => 'puppet:///modules/ktouch/en.junior.hard.ktouch.xml';

    "${ktouch_dir}/courses/fi.xml":
      require => [ Dpkg::Simpledivert["${ktouch_dir}/courses/fi.xml"],
                 , Package['ktouch'] ],
      source  => 'puppet:///modules/ktouch/fi.xml';

    "${ktouch_dir}/courses/fi.junior-remake.ktouch.xml":
      require => Package['ktouch'],
      source  => 'puppet:///modules/ktouch/fi.junior-remake.ktouch.xml';
  }

  Package <| title == ktouch |>
}

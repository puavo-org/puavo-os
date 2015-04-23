class ktouch {
  include dpkg,
          packages

  File { require => Package['ktouch'], }

  $ktouch_prefix = '/usr/share/kde4/apps/ktouch/courses'

  dpkg::simpledivert { '/usr/share/kde4/config.kcfg/ktouch.kcfg': ; }

  file {
    '/usr/share/kde4/config.kcfg/ktouch.kcfg':
      require => Dpkg::Simpledivert['/usr/share/kde4/config.kcfg/ktouch.kcfg'],
      source  => 'puppet:///modules/ktouch/ktouch.kcfg';

    "${ktouch_prefix}/en.junior.easy.ktouch.xml":
      source => 'puppet:///modules/ktouch/en.junior.easy.ktouch.xml';
 
    "${ktouch_prefix}/en.junior.hard.ktouch.xml":
      source => 'puppet:///modules/ktouch/en.junior.hard.ktouch.xml';
 
    "${ktouch_prefix}/fi.junior-remake.ktouch.xml":
      source => 'puppet:///modules/ktouch/fi.junior-remake.ktouch.xml';
  }

  Package <| title == ktouch |>
}

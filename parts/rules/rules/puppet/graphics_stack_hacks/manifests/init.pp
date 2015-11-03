class graphics_stack_hacks {
  include graphics_stack_hacks::edgers_mesa_dri,
          graphics_stack_hacks::trusty_xorg_intel,
          packages

  $altdebdir = '/var/opt/altdebs'

  file {
    $altdebdir:
      ensure => directory;
  }

  define download_alternative_deb ($file, $urlbase) {
    $targetpath = "${graphics_stack_hacks::altdebdir}/${file}"
    $url        = "${urlbase}/${file}"

    exec {
      "download $title":
        command => "/usr/bin/wget -O ${targetpath}.tmp ${url} && /bin/mv ${targetpath}.tmp ${targetpath}",
        creates => $targetpath,
        require => Package['wget'];
    }
  }

  Package <| title == wget |>
}

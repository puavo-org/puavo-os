class dconf::schemas {
  include ::packages

  $schemadir = '/usr/share/glib-2.0/schemas'

  file {
    $schemadir:
      ensure => directory;
  }

  define schema ($srcfile) {
    $filename = $title

    exec {
      "compile glib schemas for ${filename}":
        command => "/usr/bin/glib-compile-schemas ${::dconf::schemas::schemadir}",
        require => Package['libglib2.0-bin'],
        unless  => "test ${::dconf::schemas::schemadir}/gschemas.compiled -nt ${::dconf::schemas::schemadir}/${filename}";
    }

    file {
      "${::dconf::schemas::schemadir}/${filename}":
       before => Exec["compile glib schemas for ${filename}"],
       source => $srcfile;
    }
  }

  Package <| title == "libglib2.0-bin" |>
}

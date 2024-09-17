class dconf::schemas {
  include ::packages

  $schemadir = '/usr/share/glib-2.0/schemas'

  exec {
    'compile glib schemas':
      command     => '/usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas',
      refreshonly => true,
      require     => Package['libglib2.0-bin'];
  }

  file {
    $schemadir:
      ensure => directory;
  }

  define schema ($srcfile) {
    $filename = $title

    file {
      "${::dconf::schemas::schemadir}/${filename}":
       notify => Exec['compile glib schemas'],
       source => $srcfile;
    }
  }

  Package <| title == "libglib2.0-bin" |>
}

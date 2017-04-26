class dconf::schemas {
  $schemadir = '/usr/share/glib-2.0/schemas'

  exec {
    'compile glib schemas':
      command     => '/usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas',
      refreshonly => true;
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

  ::dconf::schemas::schema {
    'org.gnome.puavo.gschema.xml':
      srcfile => 'puppet:///modules/dconf/org.gnome.puavo.gschema.xml';
  }
}

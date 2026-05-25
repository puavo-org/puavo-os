class dconf {
  include ::dconf::schemas
  include ::packages

  file {
    [ '/etc/dconf'
    , '/etc/dconf/db'
    , '/etc/dconf/profile' ]:
      ensure => directory;
  }

  define configfile ($dbname, $subpath, $content) {
    exec {
      "update dconf for ${dbname}.d/${subpath}":
        command => '/usr/bin/dconf update',
        require => Package['dconf-cli'],
        unless  => "test /etc/dconf/db/${dbname} -nt /etc/dconf/db/${dbname}.d/${subpath}";
    }

    file {
      "/etc/dconf/db/${dbname}.d/${subpath}":
       before  => Exec["update dconf for ${dbname}.d/${subpath}"],
       content => $content;
    }
  }

  Package <| title == dconf-cli |>
}

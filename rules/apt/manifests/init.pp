class apt {
  define debian_repository ($localmirror='',
                            $mirror='',
                            $mirror_path='',
                            $securitymirror='',
                            $securitymirror_path='') {
    $distrib_version = $title

    file {
      "/etc/apt/preferences.d/00-${distrib_version}.pref":
        content => template('apt/00-distrib_version.pref'),
        notify  => Exec['apt update'];

      "/etc/apt/sources.list.d/${distrib_version}.list":
        content => template('apt/debian_apt_sources.list'),
        notify  => Exec['apt update'];
    }
  }

  define pin ($version) {
    $package = $title

    file {
      "/etc/apt/preferences.d/01-${package}.pref":
        content => template('apt/01-pinpackage.pref');
    }
  }

  define repository ($aptline) {
    $repository_name = $title

    file {
      "/etc/apt/sources.list.d/${repository_name}.list":
        content => "deb $aptline\ndeb-src $aptline\n",
        notify  => Exec['apt update'];
    }
  }

  exec {
    'apt update':
      command     => '/usr/bin/apt-get update',
      refreshonly => true;
  }

  file {
    '/etc/apt/apt.conf.d/00default-release':
      content => "APT::Default-Release \"${debianversioncodename}\";\n";
  }
}

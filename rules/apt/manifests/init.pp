class apt {
  define debian_repository ($localmirror='',
                            $mirror='',
                            $mirror_path='',
                            $securitymirror='',
                            $securitymirror_path='') {
    $distrib_version = $title

    file {
      "/etc/apt/preferences.d/00-${distrib_version}-backports.pref":
        content => template('apt/00-distrib_version-backports.pref'),
        notify  => Exec['apt update'];

      "/etc/apt/sources.list.d/${distrib_version}.list":
        content => template('apt/debian_apt_sources.list'),
        notify  => Exec['apt update'];
    }
  }

  define key ($key_id, $key_source) {
    $keyname = $title
    $keypath = "/etc/apt/trusted.gpg.d/$keyname"

    exec {
      "/usr/bin/apt-key add $keypath":
        notify  => Exec['apt update'],
        require => File[$keypath],
        unless  => "/usr/bin/apt-key export $key_id | grep -q 'PGP PUBLIC KEY'";
    }

    file {
      $keypath:
        source => $key_source;
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

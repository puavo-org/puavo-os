class apt {
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
}

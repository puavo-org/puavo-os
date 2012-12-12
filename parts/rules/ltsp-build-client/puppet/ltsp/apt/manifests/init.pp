class apt {
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

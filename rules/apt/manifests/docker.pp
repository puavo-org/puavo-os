class apt::docker {
  file {
    '/etc/apt/keyrings/docker.asc':
      source => 'puppet:///modules/apt/docker.asc';

    '/etc/apt/sources.list.d/docker.sources':
      content => template('apt/docker.sources'),
      notify  => Exec['apt update'];
  }
}

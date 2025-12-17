class apt::docker {
  file {
    '/etc/apt/keyrings/docker.asc':
      source => 'puppet:///modules/apt/docker.asc';

    '/etc/apt/preferences.d/30-docker.pref':
      content => template('apt/30-docker.pref');

    '/etc/apt/sources.list.d/docker.sources':
      content => template('apt/docker.sources'),
      notify  => Exec['apt update'],
      require => [ File['/etc/apt/keyrings/docker.asc']
                 , File['/etc/apt/preferences.d/30-docker.pref'] ];
  }
}

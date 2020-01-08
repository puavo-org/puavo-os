class apt::virtualbox {
  file {
    '/etc/apt/preferences.d/50-virtualbox.pref':
      content => template('apt/50-virtualbox.pref');

    '/etc/apt/sources.list.d/virtualbox.list':
      content => template('apt/virtualbox.list'),
      notify  => Exec['apt update'],
      require => File['/etc/apt/trusted.gpg.d/virtualbox.gpg'];

    '/etc/apt/trusted.gpg.d/virtualbox.gpg':
      source => 'puppet:///modules/apt/virtualbox.gpg';
  }
}

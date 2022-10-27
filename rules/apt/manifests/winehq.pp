class apt::winehq {
  file {
    '/etc/apt/keyrings':
      ensure => directory;

    '/etc/apt/preferences.d/50-winehq.pref':
      content => template('apt/50-winehq.pref');

    '/etc/apt/sources.list.d/winehq-bullseye.sources':
      content => template('apt/winehq-bullseye.sources'),
      notify  => Exec['apt update'],
      require => File['/etc/apt/keyrings/winehq-archive.key'];

    '/etc/apt/keyrings/winehq-archive.key':
      source => 'puppet:///modules/apt/winehq-archive.key';
  }
}

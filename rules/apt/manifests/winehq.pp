class apt::winehq {
  file {
    '/etc/apt/keyrings':
      ensure => directory;

    '/etc/apt/keyrings/winehq-archive.key':
      source => 'puppet:///modules/apt/winehq-archive.key';

    '/etc/apt/preferences.d/50-winehq.pref':
      content => template('apt/50-winehq.pref');

    '/etc/apt/sources.list.d/winehq.sources':
      content => template('apt/winehq.sources'),
      notify  => Exec['apt update'],
      require => File['/etc/apt/keyrings/winehq-archive.key'];
  }
}
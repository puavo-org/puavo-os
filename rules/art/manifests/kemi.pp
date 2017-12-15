class art::kemi {
  file {
    '/usr/share/kemi-art':
      ensure => directory;

    '/usr/share/kemi-art/kemi-logo.png':
      source  => 'puppet:///modules/art/kemi/kemi-logo.png';

    '/usr/share/kemi-art/kemi-login-logo.png':
      source  => 'puppet:///modules/art/kemi/kemi-login-logo.png';
  }
}

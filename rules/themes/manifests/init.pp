class themes {
  file {
    '/usr/share/themes':
      ensure => directory;

    '/usr/share/themes/Puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Puavo';
  }
}

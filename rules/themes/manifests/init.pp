class themes {
  file {
    '/usr/share/themes':
      ensure => directory;

    '/usr/share/themes/Geos-puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Geos-puavo';

    '/usr/share/themes/Puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Puavo';
  }
}

class themes {
  file {
    '/usr/share/themes':
      ensure => directory;

    '/usr/share/themes/Geos-puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Geos-puavo';

    '/usr/share/themes/Geos-puavo-dark-panel':
      recurse => true,
      source  => 'puppet:///modules/themes/Geos-puavo-dark-panel';

    '/usr/share/themes/Puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Puavo';
  }
}

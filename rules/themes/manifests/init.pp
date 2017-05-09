class themes {
  include ::gdm

  file {
    '/usr/share/themes':
      ensure => directory;

    '/usr/share/themes/Geos-puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Geos-puavo';

    '/usr/share/themes/Geos-puavo-dark-panel':
      recurse => true,
      source  => 'puppet:///modules/themes/Geos-puavo-dark-panel';

    '/usr/share/themes/Minwaita-Vanilla-Puavo':
      recurse => true,
      source  => 'puppet:///modules/themes/Minwaita-Vanilla-Puavo';

    '/usr/share/themes/Puavo':
      recurse => true,
      require => File['/etc/gdm3/background.img'],
      source  => 'puppet:///modules/themes/Puavo';
  }
}

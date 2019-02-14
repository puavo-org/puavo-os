class puavomenu {
  include ::dpkg
  include ::packages
  include ::puavo_conf

  File { require => Package['puavomenu'], }

  file {
    '/etc/puavomenu':
      ensure => directory;

    '/etc/puavomenu/dirs.json':
      content => template('puavomenu/dirs.json');

    '/etc/puavomenu/conditions':
      ensure => directory;

    '/etc/puavomenu/conditions/50-default.yml':
      content => template('puavomenu/conditions/50-default.yml');

    '/etc/puavomenu/menudata':
      ensure => directory;

    '/etc/puavomenu/menudata/50-default.yml':
      content => template('puavomenu/menudata/50-default.yml');

    '/etc/X11/Xsession.d/48puavo-menu-show-my-school-users':
      source => 'puppet:///modules/puavomenu/48puavo-menu-show-my-school-users';

    '/opt/puavomenu/icons':
      recurse => true,
      source  => 'puppet:///modules/puavomenu/icons';

    '/usr/share/icons/opinsys-nelio-menu.png':
      source => 'puppet:///modules/puavomenu/icons/opinsys-nelio-menu.png';
  }

  ::puavo_conf::definition {
    'puavomenu.json':
      source => 'puppet:///modules/puavomenu/puavomenu.json';
  }

  Package <| title == puavomenu |>
}

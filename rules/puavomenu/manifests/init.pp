class puavomenu {
  include ::dpkg
  include ::packages
  include ::puavo_conf

  File { require => Package['puavomenu'], }

  file {
    '/etc/puavomenu':
      ensure => directory;

    '/etc/puavomenu/conditions.yaml':
      content => template('puavomenu/conditions.yaml');

    '/etc/puavomenu/menudata.yaml':
      content => template('puavomenu/menudata.yaml');

    '/etc/X11/Xsession.d/48puavo-menu-show-my-school-users':
      source => 'puppet:///modules/puavomenu/48puavo-menu-show-my-school-users';

    '/opt/puavomenu/icons':
      recurse => true,
      source  => 'puppet:///modules/puavomenu/icons';
  }

  ::puavo_conf::definition {
    'puavomenu.json':
      source => 'puppet:///modules/puavomenu/puavomenu.json';
  }

  Package <| title == puavomenu |>
}

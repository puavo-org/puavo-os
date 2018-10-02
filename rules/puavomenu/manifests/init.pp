class puavomenu {
  include ::dpkg
  include ::packages
  include ::puavo_conf

  File { require => Package['puavomenu'], }

  file {
    '/etc/puavomenu':
      ensure => directory;

    '/etc/puavomenu/menudata.yaml':
      content => template('puavomenu/menudata.yaml');

    '/etc/puavomenu/conditions.yaml':
      content => template('puavomenu/conditions.yaml');
  }

  ::puavo_conf::definition {
    'puavomenu.json':
      source => 'puppet:///modules/puavomenu/puavomenu.json';
  }
}

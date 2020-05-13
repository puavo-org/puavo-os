class puavomenu {
  include ::dpkg
  include ::packages
  include ::puavo_conf
  include ::puavo_external_files

  File { require => Package['puavomenu'], }

  file {
    '/etc/puavo-external-files-actions.d/puavomenu':
      mode   => '0755',
      source => 'puppet:///modules/puavomenu/etc_puavo-external-files-actions.d_puavomenu';

    '/etc/puavomenu':
      ensure => directory;

    '/etc/puavomenu/dirs.json':
      content => template('puavomenu/dirs.json');

    '/etc/puavomenu/conditions':
      ensure => directory;

    '/etc/puavomenu/conditions/50-default.json':
      content => template('puavomenu/conditions/50-default.json');

    '/etc/puavomenu/menudata':
      ensure => directory;

    '/etc/puavomenu/menudata/50-default.json':
      content => template('puavomenu/menudata/50-default.json');

    '/etc/puavomenu/menudata/60-ktp.json':
      content => template('puavomenu/menudata/60-ktp.json');

    '/etc/puavomenu/menudata/70-googleapps.json':
      content => template('puavomenu/menudata/70-googleapps.json');

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

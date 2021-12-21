class veyon {
  include ::dpkg
  include ::packages
  include ::puavo_conf

  ::dpkg::simpledivert {
    '/usr/bin/veyon-server':
      require => Package['veyon-service'];
  }

  file {
    '/usr/bin/veyon-server':
      mode    => '0755',
      require => ::Dpkg::Simpledivert['/usr/bin/veyon-server'],
      source  => 'puppet:///modules/veyon/veyon-server';

    '/usr/local/lib/puavo-veyon':
      ensure => directory;

    '/usr/local/lib/puavo-veyon/x11vnc':
      mode    => '0755',
      require => Package['x11vnc'],
      source  => 'puppet:///modules/veyon/x11vnc';
  }

  ::puavo_conf::definition {
    'puavo-veyon.json':
      source => 'puppet:///modules/veyon/puavo-veyon.json';
  }

  ::puavo_conf::script {
    'setup_veyon':
      source => 'puppet:///modules/veyon/setup_veyon';
  }

  Package <|
       title == "veyon-service"
    or title == "x11vnc"
  |>
}

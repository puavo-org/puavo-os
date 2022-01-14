class veyon {
  include ::dpkg
  include ::packages
  include ::puavo_conf

  ::dpkg::simpledivert {
    '/usr/bin/veyon-server':
      require => Package['veyon-service'];
  }

  file {
    '/etc/dbus-1/system.d/org.puavo.Veyon.conf':
      require => Package['dbus'],
      source  => 'puppet:///modules/veyon/org.puavo.Veyon.conf';

    '/etc/systemd/system/multi-user.target.wants/puavo-veyon.service':
      ensure  => 'link',
      require => [ File['/lib/systemd/system/puavo-veyon.service']
                 , Package['systemd'] ],
      target  => '/lib/systemd/system/puavo-veyon.service';

    '/lib/systemd/system/puavo-veyon.service':
      require => [ File['/usr/local/sbin/puavo-veyon']
                 , Package['systemd'] ],
      source  => 'puppet:///modules/veyon/puavo-veyon.service';

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

    '/usr/local/sbin/puavo-veyon':
      mode    => '0755',
      source  => 'puppet:///modules/veyon/puavo-veyon';
  }

  ::puavo_conf::definition {
    'puavo-veyon.json':
      source => 'puppet:///modules/veyon/puavo-veyon.json';
  }

  Package <|
       title == "dbus"
    or title == "veyon-service"
    or title == "x11vnc"
  |>
}

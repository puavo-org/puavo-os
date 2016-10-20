class bootserver_vpn {
  include bootserver_config

  file {
    '/etc/openvpn/altvpn1.conf':
      content => template('bootserver_vpn/altvpn1.conf');

    '/etc/openvpn/puavo.conf':
      content => template('bootserver_vpn/puavo.conf');

    '/usr/local/lib/puavo-openvpn-up':
      content => template('bootserver_vpn/puavo-openvpn-up'),
      mode    => 0755;
  }

  service {
    'altvpn1':
      ensure  => running,
      require => File['/etc/openvpn/altvpn1.conf'],
      restart => '/usr/sbin/service openvpn reload altvpn1',
      start   => '/usr/sbin/service openvpn start altvpn1',
      status  => '/usr/sbin/service openvpn status altvpn1',
      stop    => '/usr/sbin/service openvpn stop altvpn1';

    'vpn1':
      ensure  => running,
      require => [ File['/etc/openvpn/puavo.conf']
                 , File['/usr/local/lib/puavo-openvpn-up'] ],
      restart => '/usr/sbin/service openvpn reload puavo',
      start   => '/usr/sbin/service openvpn start puavo',
      status  => '/usr/sbin/service openvpn status puavo',
      stop    => '/usr/sbin/service openvpn stop puavo';
  }

}

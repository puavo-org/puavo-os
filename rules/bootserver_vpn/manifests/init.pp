class bootserver_vpn {

  file {
    '/etc/openvpn/altvpn1.conf':
      content => template('bootserver_vpn/altvpn1.conf');

    '/etc/openvpn/puavo.conf':
      content => template('bootserver_vpn/puavo.conf');
  }

  service {
    'altvpn1':
      ensure  => running,
      require => File['/etc/openvpn/altvpn1.conf'],
      restart => '/usr/sbin/service openvpn restart altvpn1',
      start   => '/usr/sbin/service openvpn start altvpn1',
      status  => '/usr/sbin/service openvpn status altvpn1',
      stop    => '/usr/sbin/service openvpn stop altvpn1';

    'vpn1':
      ensure  => running,
      require => File['/etc/openvpn/puavo.conf'],
      restart => '/usr/sbin/service openvpn restart puavo',
      start   => '/usr/sbin/service openvpn start puavo',
      status  => '/usr/sbin/service openvpn status puavo',
      stop    => '/usr/sbin/service openvpn stop puavo';
  }

}

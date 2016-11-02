class bootserver_vpn {
  include bootserver_config

  file {
    '/etc/openvpn/altvpn1.conf':
      content => template('bootserver_vpn/altvpn1.conf'),
      notify  => Service['openvpn'];

    '/etc/openvpn/puavo.conf':
      content => template('bootserver_vpn/puavo.conf'),
      notify  => Service['openvpn'];

    '/usr/local/lib/puavo-openvpn-up':
      content => template('bootserver_vpn/puavo-openvpn-up'),
      mode    => 0755,
      notify  => Service['openvpn'];
  }

  service {
    'openvpn':
      enable => true,
      ensure => running;
  }
}

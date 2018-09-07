class bootserver_vpn {
  include bootserver_config

  file {
    '/etc/openvpn/puavo.conf':
      content => template('bootserver_vpn/puavo.conf');

    '/usr/local/lib/puavo-openvpn-up':
      content => template('bootserver_vpn/puavo-openvpn-up'),
      mode    => '0755';
  }
}

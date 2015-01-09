class bootserver_ddns {

  if $ltsp_iface_ip == undef {
    fail("ltsp_iface_ip fact is missing")
  }

  file {
    '/etc/dhcp/dhcpd.conf':
      notify  => Service['isc-dhcp-server'],
      content => template('bootserver_ddns/dhcpd.conf');

    '/etc/dnsmasq.conf':
      notify  => Service['dnsmasq'],
      content => template('bootserver_ddns/dnsmasq.conf');
  }

  service {
    'dnsmasq':
      enable => true,
      ensure => 'running';

    'isc-dhcp-server':
      enable => true,
      ensure => 'running';
  }

}

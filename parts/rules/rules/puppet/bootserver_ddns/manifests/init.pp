class bootserver_ddns {

  if $ltsp_iface_ip == undef {
    fail("ltsp_iface_ip fact is missing")
  }

  file {
    '/etc/dnsmasq.conf':
      notify  => Service['dnsmasq'],
      content => template('bootserver_ddns/dnsmasq.conf');
  }

  service {
    'dnsmasq':
      enable => true,
      ensure => 'running';
  }

}

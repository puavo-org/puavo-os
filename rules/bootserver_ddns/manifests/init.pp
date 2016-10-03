class bootserver_ddns {

  if $ltsp_iface_ip == undef {
    fail("ltsp_iface_ip fact is missing")
  }

  exec {
    'ensure ubnt.conf exists':
      command => '/usr/local/lib/create-dummy-ubnt-conf',
      creates => '/etc/dhcp/ubnt.conf',
      require => Package['isc-dhcp-server'];
  }

  file {
    '/usr/local/lib/create-dummy-ubnt-conf':
      content => template('bootserver_ddns/create-dummy-ubnt-conf'),
      mode    => 0755;

    '/etc/apparmor.d/local/usr.sbin.dhcpd':
      content => template('bootserver_ddns/dhcpd.apparmor'),
      mode    => 0644,
      notify  => Service['apparmor'],
      require => Package['apparmor'];
    
    '/etc/dhcp/dhcpd.conf':
      notify  => Service['isc-dhcp-server'],
      content => template('bootserver_ddns/dhcpd.conf'),
      require => [ Package['isc-dhcp-server']
                 , Exec['ensure ubnt.conf exists'] ];
    '/etc/dnsmasq.conf':
      notify  => Service['dnsmasq'],
      content => template('bootserver_ddns/dnsmasq.conf'),
      require => Package['dnsmasq'];
  }
  
  package {
    [ 'bind9'
    , 'dnsmasq'
    , 'isc-dhcp-server' ]:
      ensure => present;
  }

  service {
    'bind9':
      enable => true,
      ensure => 'running';

    'dnsmasq':
      enable => true,
      ensure => 'running';

    'isc-dhcp-server':
      enable => true,
      ensure => 'running';
  }

}

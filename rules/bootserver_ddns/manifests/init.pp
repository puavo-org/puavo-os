class bootserver_ddns {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/bind/named.conf.options':
      group   => 'bind',
      require => Package['bind9'],
      source  => 'puppet:///modules/bootserver_ddns/named.conf.options';

    '/etc/cron.d/puavo-update-airprint-ddns':
      require => File['/usr/local/sbin/puavo-update-airprint-ddns'],
      source  => 'puppet:///modules/bootserver_ddns/puavo-update-airprint-ddns.cron';

    '/usr/local/lib/puavo-update-ddns':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_ddns/puavo-update-ddns';

    '/usr/local/sbin/puavo-update-airprint-ddns':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_ddns/puavo-update-airprint-ddns';
  }

  ::puavo_conf::definition {
    'puavo-networking.json':
      source => 'puppet:///modules/bootserver_ddns/puavo-networking.json';
  }

  ::puavo_conf::script {
    'setup_dhcpd':
      require => [ Package['moreutils']
                 , Package['ruby-ipaddress'] ],
      source  => 'puppet:///modules/bootserver_ddns/setup_dhcpd';

    'setup_dns':
      require => [ File['/usr/local/lib/puavo-update-ddns']
                 , Package['bind9']
                 , Package['bind9utils']
                 , Package['isc-dhcp-server']
                 , Package['moreutils'] ],
      source  => 'puppet:///modules/bootserver_ddns/setup_dns';
  }

  Package <| title == 'bind9'
          or title == 'bind9utils'
          or title == 'dnsmasq'
          or title == 'isc-dhcp-server'
          or title == 'moreutils'
          or title == 'ruby-ipaddress' |>
}

#{
#  if $ltsp_iface_ip == undef {
#    fail('ltsp_iface_ip fact is missing')
#  }
#
#  file {
#    '/etc/apparmor.d/local/usr.sbin.dhcpd':
#      content => template('bootserver_ddns/dhcpd.apparmor'),
#      mode    => '0644',
#      require => Package['apparmor'];
#  }
#}

class bootserver_ddns {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-networking.json':
      source => 'puppet:///modules/bootserver_ddns/puavo-networking.json';
  }

  ::puavo_conf::script {
    'setup_bind':
      require => [ Package['bind9']
                 , Package['bind9utils']
                 , Package['isc-dhcp-server']
                 , Package['moreutils'] ],
      source  => 'puppet:///modules/bootserver_ddns/setup_bind';

    'setup_dhcpd':
      require => [ Package['moreutils']
                 , Package['ruby-ipaddress'] ],
      source  => 'puppet:///modules/bootserver_ddns/setup_dhcpd';
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
#  define scriptfile($type) {
#    case $type {
#      'lib', 'bin', 'sbin': { }
#      default             : { fail('type must be lib, bin or sbin') }
#    }
#
#    file {
#        "/usr/local/${type}/${title}":
#          content => template("bootserver_ddns/${title}"),
#          mode    => '0755';
#    }
#  }
#
#  ::bootserver_ddns::scriptfile {
#    'puavo-update-airprint-ddns':
#      type => 'sbin';
#
#    'puavo-update-ddns':
#      type => 'lib';
#  }
#
#
#  file {
#    '/etc/apparmor.d/local/usr.sbin.dhcpd':
#      content => template('bootserver_ddns/dhcpd.apparmor'),
#      mode    => '0644',
#      require => Package['apparmor'];
#
#    '/etc/bind/named.conf.local':
#      content => template('bootserver_ddns/named.conf.local');
#
#    '/etc/bind/named.conf.options':
#      content => template('bootserver_ddns/named.conf.options');
#
#    '/etc/cron.d/puavo-update-airprint-ddns':
#      content => template('bootserver_ddns/puavo-update-airprint-ddns.cron'),
#      mode    => '0644',
#      require => Bootserver_ddns::Scriptfile['puavo-update-airprint-ddns'];
#
#    '/etc/dnsmasq.conf':
#      content => template('bootserver_ddns/dnsmasq.conf'),
#      require => Package['dnsmasq'];
#
#    '/etc/sudoers.d/puavo-bootserver':
#      content => template('bootserver_ddns/sudoers'),
#      mode    => '0440';
#  }
#}

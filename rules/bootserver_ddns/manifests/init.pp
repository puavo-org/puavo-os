class bootserver_ddns {

  $arpazone = '10.in-addr.arpa'
  $ddns_key = '/etc/dhcp/ddns-keys/nsupdate.key'

  if $ltsp_iface_ip == undef {
    fail('ltsp_iface_ip fact is missing')
  }

  define zonefile() {
    $zone               = $title
    $zonefile           = "/var/lib/bind/${zone}"
    $zonefile_by_puppet = "${zonefile}.by_puppet"

    exec {
      "reset zone ${zone}":
        command     => "/usr/local/lib/reset-zone '${zonefile_by_puppet}' '${zonefile}'",
        creates     => $zonefile,
        notify      => Service['bind9'],
        require     => [ File[$zonefile_by_puppet]
                       , Package['bind9utils'] ];
    }

    file {
      $zonefile:
        group   => 'bind',
        mode    => 0644,
        owner   => 'bind',
        require => Exec["reset zone ${zone}"];

      $zonefile_by_puppet:
        content => template("bootserver_ddns/${zone}"),
        mode    => 0644;
    }
  }

  define scriptfile($type) {
    case $type {
      'lib', 'bin', 'sbin': { }
      default             : { fail('type must be lib, bin or sbin') }
    }

    file {
        "/usr/local/${type}/${title}":
          content => template("bootserver_ddns/${title}"),
          mode    => 0755;
    }
  }

  ::bootserver_ddns::scriptfile {
    [ 'create-dummy-ubnt-conf'
    , 'create-ddns-key'
    , 'puavo-update-ddns'
    , 'reset-zone']:
      type => 'lib';

    'puavo-update-airprint-ddns':
      type => 'sbin';
  }

  ::bootserver_ddns::zonefile {
    [ 'puavo_domain'
    , 'puavo_domain_reverse' ]:
      ;
  }

  exec {
    'ensure ubnt.conf exists':
      command => '/usr/local/lib/create-dummy-ubnt-conf',
      creates => '/etc/dhcp/ubnt.conf',
      require => Package['isc-dhcp-server'];

    'create ddns key':
      command => "/usr/local/lib/create-ddns-key '${ddns_key}'",
      creates => $ddns_key;
  }

  file {
    $ddns_key:
      group   => 'dhcpd',
      mode    => 0640,
      require => Exec['create ddns key'];

    '/etc/apparmor.d/local/usr.sbin.dhcpd':
      content => template('bootserver_ddns/dhcpd.apparmor'),
      mode    => 0644,
      notify  => Service['apparmor'],
      require => Package['apparmor'];

    '/etc/bind/named.conf.local':
      content => template('bootserver_ddns/named.conf.local'),
      notify  => Service['bind9'];

    '/etc/bind/named.conf.options':
      content => template('bootserver_ddns/named.conf.options'),
      notify  => Service['bind9'];

    '/etc/bind/nsupdate.key':
      group   => 'bind',
      mode    => 0640,
      notify  => Service['bind9'],
      require => [ File[$ddns_key]
                 , Package['bind9'] ],
      source  => "file://${ddns_key}";

    '/etc/cron.d/puavo-update-airprint-ddns':
      content => template('bootserver_ddns/puavo-update-airprint-ddns.cron'),
      mode    => 0644,
      require => Bootserver_ddns::Scriptfile['puavo-update-airprint-ddns'];

    '/etc/dhcp/dhcpd.conf':
      content => template('bootserver_ddns/dhcpd.conf'),
      notify  => Service['isc-dhcp-server'],
      require => [ Package['isc-dhcp-server']
                 , Exec['ensure ubnt.conf exists'] ];

    '/etc/dnsmasq.conf':
      content => template('bootserver_ddns/dnsmasq.conf'),
      notify  => Service['dnsmasq'],
      require => Package['dnsmasq'];
  }

  package {
    [ 'bind9'
    , 'bind9utils'
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
      ensure => 'running',
      require => Service['bind9'];

    'isc-dhcp-server':
      enable => true,
      ensure => 'running',
      require => [ Bootserver_ddns::Scriptfile['puavo-update-ddns']
                 , Service['bind9']
                 , Service['dnsmasq'] ];
  }
}

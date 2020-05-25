class bootserver_firewall {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/default/shorewall':
      require => Package['shorewall'],
      source  => 'puppet:///modules/bootserver_firewall/etc_default_shorewall';

    '/etc/logrotate.d/ulogd2':
      require => Package['ulogd2'],
      source  => 'puppet:///modules/bootserver_firewall/etc_logrotate.d_ulogd2';

    '/etc/shorewall/Makefile':
      require => Package['shorewall'],
      source  => 'puppet:///modules/bootserver_firewall/etc_shorewall/Makefile';

    '/etc/shorewall/shorewall.conf':
      require => Package['shorewall'],
      source  => 'puppet:///modules/bootserver_firewall/etc_shorewall/shorewall.conf';

    '/etc/ulogd.conf':
      mode    => '0600',
      require => Package['ulogd2'],
      source  => 'puppet:///modules/bootserver_firewall/ulogd.conf';
  }

  ::puavo_conf::definition {
    'puavo-admin-logging-firewall.json':
      source => 'puppet:///modules/bootserver_firewall/puavo-admin-logging-firewall.json';
  }

  ::puavo_conf::script {
    'setup_bootserver_shorewall_conf':
      require => ::Puavo_conf::Definition['puavo-admin-logging-firewall.json'],
      source  => 'puppet:///modules/bootserver_firewall/setup_bootserver_shorewall_conf';

    'setup_firewall':
      source => 'puppet:///modules/bootserver_firewall/setup_firewall';
  }

  Package <| title == shorewall or title == ulogd2 |>
}

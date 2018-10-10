class bootserver_firewall {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/default/shorewall':
      require => Package['shorewall'],
      source  => 'puppet:///modules/bootserver_firewall/etc_default_shorewall';

    '/etc/shorewall/Makefile':
      require => Package['shorewall'],
      source  => 'puppet:///modules/bootserver_firewall/etc_shorewall/Makefile';

    '/etc/shorewall/shorewall.conf':
      require => Package['shorewall'],
      source  => 'puppet:///modules/bootserver_firewall/etc_shorewall/shorewall.conf';
  }

  ::puavo_conf::script {
    'setup_bootserver_shorewall_conf':
      source => 'puppet:///modules/bootserver_firewall/setup_bootserver_shorewall_conf';

    'setup_firewall':
      source => 'puppet:///modules/bootserver_firewall/setup_firewall';
  }

  Package <| title == shorewall |>
}

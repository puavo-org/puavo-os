class bootserver_network_interfaces {
  include ::bootserver_config

  file {
    '/etc/network/interfaces.by_puppet':
      content => template('bootserver_network_interfaces/etc_network_interfaces');

    '/etc/network/if-up.d/disable_flow_control':
      content => template('bootserver_network_interfaces/etc/network/if-up.d/disable_flow_control'),
      mode    => 755
  }
}

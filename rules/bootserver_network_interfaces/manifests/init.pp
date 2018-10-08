class bootserver_network_interfaces {
  include ::puavo_conf

  file {
    '/etc/network/if-up.d/disable_flow_control':
      content => template('bootserver_network_interfaces/etc/network/if-up.d/disable_flow_control'),
      mode    => '0755';
  }

  ::puavo_conf::script {
    'setup_network_interfaces':
      source => 'puppet:///modules/bootserver_network_interfaces/setup_network_interfaces';

    'setup_persistent_net_rules':
      source => 'puppet:///modules/bootserver_network_interfaces/setup_persistent_net_rules';
  }
}

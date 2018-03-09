class bootserver_network_interfaces {
  include ::puavo_conf

  define setup_if_conf() {
    $interface_name = $title

    file {
      "/etc/network/interfaces.bootserver.d/${interface_name}":
        content => template("bootserver_network_interfaces/etc/network/interfaces.d/${interface_name}");
    }
  }

  file {
    '/etc/network/interfaces.bootserver.d':
      ensure => directory;

    '/etc/network/if-up.d/disable_flow_control':
      content => template('bootserver_network_interfaces/etc/network/if-up.d/disable_flow_control'),
      mode    => '0755';
  }

  ::bootserver_network_interfaces::setup_if_conf {
    [ 'lo', 'inet0', 'ltsp0', 'wlan0', ]: ;
  }

  ::puavo_conf::script {
    'setup_network_interfaces':
      source => 'puppet:///modules/bootserver_network_interfaces/setup_network_interfaces';
  }
}

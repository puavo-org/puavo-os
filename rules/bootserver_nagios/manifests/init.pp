class bootserver_nagios {
  include ::dpkg
  include ::packages

  ::puavo_conf::definition {
    'puavo-nagios.json':
      source => 'puppet:///modules/bootserver_nagios/puavo-nagios.json';
  }

  ::puavo_conf::script {
    'setup_nagios':
      require => [ ::Dpkg::Statoverride['/usr/lib/nagios/plugins/check_dhcp']
                 , ::Puavo_conf::Definition['puavo-nagios.json'] ],
      source  => 'puppet:///modules/bootserver_nagios/setup_nagios';
  }

  dpkg::statoverride {
    '/usr/lib/nagios/plugins/check_dhcp':       # set check_dhcp setuid root
      owner   => 'root',
      group   => 'nagios',
      mode    => 4750,
      require => Package['nagios-nrpe-server'];
  }

  Package <| title == nagios-nrpe-server |>
}

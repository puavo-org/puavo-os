class bootserver_dummywlan {
  include ::bootserver_ddns
  include ::bootserver_kernel_modules

  bootserver_kernel_modules::add {
    'dummy':
      ;
  }

  exec {
    '/usr/local/lib/dummywlan':
      onlyif  => '/usr/bin/test ! -e /sys/class/net/wlan0/lower_dummywlan0',
      notify  => Service['isc-dhcp-server'],
      require => Bootserver_kernel_modules::Add['dummy'];
  }

  file {
    '/etc/init/dummywlan.conf':
      content => template('bootserver_dummywlan/dummywlan.upstart.conf'),
      mode    => 0644,
      require => File['/usr/local/lib/dummywlan'];

    '/etc/init.d/dummywlan':
      ensure  => link,
      target  => '/lib/init/upstart-job',
      require => File['/etc/init/dummywlan.conf'];

    '/etc/init/isc-dhcp-server.override':
      content => template('bootserver_dummywlan/isc-dhcp-server.upstart.override'),
      mode    => 0644;

    '/usr/local/lib/dummywlan':
      content => template('bootserver_dummywlan/dummywlan'),
      mode    => 0755;
  }

  service {
    'dummywlan':
      enable  => true,
      require => [ Bootserver_kernel_modules::Add['dummy']
                 , File['/etc/init.d/dummywlan'] ],
      notify  => Service['isc-dhcp-server'];
  }
}

class bootserver_nbd_server {

  file {

    '/etc/init.d/nbd-server':
      mode   => 0755,
      source => 'puppet:///modules/bootserver_nbd_server/nbd-server.init';

    '/etc/nbd-server/config':
      mode   => 0644,
      notify => Service['nbd-server'],
      source => 'puppet:///modules/bootserver_nbd_server/config';

  }

  service {

    'nbd-server':
      enable => true,
      ensure => running,
      status => '/usr/bin/lsof -t -u nbd -a -iTCP:10809 -sTCP:LISTEN';

  }

}

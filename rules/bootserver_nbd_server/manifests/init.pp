class bootserver_nbd_server {
  file {
    '/etc/init.d/nbd-server':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_nbd_server/nbd-server.init';

    '/etc/nbd-server/config':
      mode   => '0644',
      source => 'puppet:///modules/bootserver_nbd_server/config';

  }
}

class bootserver_nfs {
  include ::puavo_conf

  file {
    '/etc/default/nfs-common':
      content => template('bootserver_nfs/etc_default_nfs-common');

    '/etc/default/nfs-kernel-server':
      content => template('bootserver_nfs/etc_default_nfs-kernel-server');
  }

  ::puavo_conf::script {
    'setup_nfs_server':
      source => 'puppet:///modules/bootserver_nfs/setup_nfs_server';
  }
}

class bootserver_nfs {
  include ::puavo_conf

  file {
    '/etc/default/nfs-common':
      content => template('bootserver_nfs/etc_default_nfs-common');

    '/etc/default/nfs-kernel-server':
      content => template('bootserver_nfs/etc_default_nfs-kernel-server');

    '/etc/systemd/system/nfsdcld.service.d':
      ensure => directory;

    '/etc/systemd/system/nfsdcld.service.d/create_statedir.conf':
      content => template('bootserver_nfs/create_statedir.conf');
  }

  ::puavo_conf::script {
    'setup_nfs_server':
      source => 'puppet:///modules/bootserver_nfs/setup_nfs_server';
  }
}

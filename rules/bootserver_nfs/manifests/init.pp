class bootserver_nfs {
  include puavo

  augeas {
    'add /export/home to /etc/fstab':
      context => '/files/etc/fstab',
      changes => [
        "set 01/spec    /home",
        "set 01/file    /export/home",
        "set 01/vfstype none",
        "set 01/opt[1]  rw",
        "set 01/opt[2]  bind",
        "set 01/dump    0",
        "set 01/passno  0",
      ],
      notify  => Exec['/bin/mount -a'],
      onlyif  => "match *[spec='/home'][file = '/export/home'] size == 0",
      require => File['/export/home'];
  }

  Exec { notify => [ Service['idmapd'], Service['nfs-kernel-server'], ], }
  exec {
    '/bin/mount -a':
      refreshonly => true;
  }

  File { notify => [ Service['idmapd'], Service['nfs-kernel-server'], ], }
  file {
    '/etc/default/nfs-common':
      content => template('bootserver_nfs/etc_default_nfs-common');

    '/etc/default/nfs-kernel-server':
      content => template('bootserver_nfs/etc_default_nfs-kernel-server');

    '/etc/exports':
      content => template('bootserver_nfs/etc_exports');

    '/etc/idmapd.conf':
      content => template('bootserver_nfs/etc_idmapd.conf');

    [ '/export', '/export/home', ]:
      ensure => directory;
  }

  service {
    [ 'idmapd', 'nfs-kernel-server', ]:
      ensure => running;
  }
}

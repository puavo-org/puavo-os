class initramfs {

  exec {
    'initramfs::update':
      command     => '/usr/sbin/update-initramfs -k all -u',
      refreshonly => true;
  }

}

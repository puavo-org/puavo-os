class initramfs {
  exec {
    'update initramfs':
      command     => '/usr/sbin/update-initramfs -k all -u',
      refreshonly => true;
  }
}

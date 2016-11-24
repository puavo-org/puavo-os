class disable_update_initramfs {
  include ::puavo_conf

  ::puavo_conf::script {
    'disable_update_initramfs':
      source => 'puppet:///modules/disable_update_initramfs/disable_update_initramfs';
  }
}

class apt::no_initramfs_tools {
  file {
    '/etc/apt/preferences.d/10-no-initramfs-tools.pref':
      source => 'puppet:///modules/apt/10-no-initramfs-tools.pref';
  }
}

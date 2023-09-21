class initramfs {
  include ::packages

  file {
    '/etc/initramfs-tools/initramfs.conf':
      require => Package['initramfs-tools'],
      source  => 'puppet:///modules/initramfs/initramfs.conf';

    '/etc/initramfs-tools/modules':
      require => Package['initramfs-tools'],
      source  => 'puppet:///modules/initramfs/etc_initramfs-tools_modules';

    # live-tools is required because it sets up a divert
    '/usr/sbin/update-initramfs':
      mode    => '0755',
      require => [ Package['initramfs-tools']
                 , Package['live-tools'] ],
      source  => 'puppet:///modules/initramfs/update-initramfs';
  }

  Package <| title == "initramfs-tools" or title == "live-tools" |>
}

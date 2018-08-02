class abitti {
  include ::initramfs
  include ::packages
  include ::puavo_conf

  file {
    '/usr/share/initramfs-tools/scripts/init-bottom/puavo-abitti':
      mode    => '0755',
      notify  => Exec['update initramfs'],
      require => [ Package['live-boot']
                 , Package['live-boot-initramfs-tools']
                 , Package['live-config']
                 , Package['live-config-systemd']
                 , Package['live-tools'] ],
      source  => 'puppet:///modules/abitti/puavo-abitti';
  }

  ::puavo_conf::definition {
    'puavo-abitti.json':
      source => 'puppet:///modules/abitti/puavo-abitti.json';
  }

  Package <|
       title == live-boot
    or title == live-boot-initramfs-tools
    or title == live-config
    or title == live-config-systemd
    or title == live-tools
  |>
}

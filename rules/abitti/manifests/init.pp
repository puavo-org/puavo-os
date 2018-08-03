class abitti {
  include ::initramfs
  include ::packages
  include ::puavo_conf

  file {
    '/etc/systemd/system/multi-user.target.wants/puavo-trigger-abitti-updates.service':
      ensure  => link,
      require => File['/etc/systemd/system/puavo-trigger-abitti-updates.service'],
      target  => '/etc/systemd/system/puavo-trigger-abitti-updates.service';

    '/etc/systemd/system/puavo-trigger-abitti-updates.service':
      require => File['/usr/local/lib/puavo-trigger-abitti-updates'],
      source  => 'puppet:///modules/abitti/puavo-trigger-abitti-updates.service';

    '/usr/local/lib/puavo-trigger-abitti-updates':
      mode    => '0755',
      require => File['/usr/local/sbin/puavo-update-abitti-image'],
      source  => 'puppet:///modules/abitti/puavo-trigger-abitti-updates';

    '/usr/local/sbin/puavo-update-abitti-image':
      mode    => '0755',
      require => ::Puavo_conf::Definition['puavo-abitti.json'],
      source  => 'puppet:///modules/abitti/puavo-update-abitti-image';

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

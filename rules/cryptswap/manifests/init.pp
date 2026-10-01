class cryptswap {
  include ::packages

  file {
    '/etc/systemd/system/systemd-cryptsetup@.service.d':
      ensure  => directory,
      require => Package['systemd'];

    '/etc/systemd/system/systemd-cryptsetup@.service.d/50-puavo-udev-change.conf':
      source => 'puppet:///modules/cryptswap/50-puavo-udev-change.conf';
  }

  Package <| title == systemd |>
}

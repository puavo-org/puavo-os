class disable_suspend_on_nbd_devices {
  include packages

  file {
    '/etc/pm/sleep.d/01_nbd_test':
      mode    => '0755',
      require => Package['pm-utils'],
      source  => 'puppet:///modules/disable_suspend_on_nbd_devices/01_nbd_test';
  }

  Package <| title == pm-utils |>
}

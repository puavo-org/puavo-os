class disable_suspend_by_tag {
  include ::initramfs
  include ::packages

  file {
    '/etc/pm/sleep.d/02_nosuspendtag_test':
      mode    => '0755',
      require => Package['pm-utils'],
      source  => 'puppet:///modules/disable_suspend_by_tag/02_nosuspendtag_test';
  }

  Package <| title == pm-utils |>
}

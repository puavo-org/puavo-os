class disable_suspend_on_halt {
  include ::packages

  file {
    '/etc/pm/sleep.d/00_runlevel_test':
      mode    => '0755',
      require => Package['pm-utils'],
      source  => 'puppet:///modules/disable_suspend_on_halt/00_runlevel_test';
  }

  Package <| title == pm-utils |>
}

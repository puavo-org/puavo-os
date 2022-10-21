class udev::avoid_ac_unplug_sleep {
  include packages

  file {
    '/etc/udev/rules.d/84-avoid-ac-unplug-sleep.rules':
      content => template('udev/84-avoid-ac-unplug-sleep.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

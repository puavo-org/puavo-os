class udev::microbit {
  include packages

  file {
    '/etc/udev/rules.d/42-microbit.rules':
      content => template('udev/42-microbit.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

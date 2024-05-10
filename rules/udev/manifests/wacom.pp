class udev::wacom {
  include ::packages

  file {
    '/etc/udev/rules.d/60-wacom.rules':
      content => template('udev/60-wacom.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

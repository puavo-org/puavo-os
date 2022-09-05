class udev::vernier {
  include packages

  file {
    '/etc/udev/rules.d/40-vstlibusb.rules':
      content => template('udev/40-vstlibusb.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

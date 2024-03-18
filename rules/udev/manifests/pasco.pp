class udev::pasco {
  include packages

  file {
    '/etc/udev/rules.d/41-pasco.rules':
      content => template('udev/41-pasco.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

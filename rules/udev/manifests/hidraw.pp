class udev::hidraw {
  include ::packages

  file {
    '/etc/udev/rules.d/95-hidraw.rules':
      content => template('udev/95-hidraw.rules'),
      require => [ Package['udev'] ];
  }

  Package <| title == udev |>
}

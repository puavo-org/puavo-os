class udev::unblock_wifi {
  include dpkg,
    packages

  file {
    '/etc/udev/rules.d/80-unblock-wifi.rules':
      content => template('udev/80-unblock-wifi.rules'),
      require => [ Package['udev'] ];
  }

  Package <| (title == udev) |>
}

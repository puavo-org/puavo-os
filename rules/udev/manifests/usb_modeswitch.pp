class udev::usb_modeswitch {
  include ::dpkg
  include ::packages

  dpkg::simpledivert {
    '/usr/lib/udev/rules.d/40-usb_modeswitch.rules':
      require => Package['usb-modeswitch-data'];
  }

  file {
    '/usr/lib/udev/rules.d/40-usb_modeswitch.rules':
      content => template('udev/40-usb_modeswitch.rules'),
      require => ::Dpkg::Simpledivert['/usr/lib/udev/rules.d/40-usb_modeswitch.rules'];
  }

  Package <| title == "usb-modeswitch-data" |>
}

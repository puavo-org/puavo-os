class udev::interface_renaming {
  # Do not let systemd-udevd mess with interface names, needed by
  # puavo-wlanap.  This path is special and tested by at least
  # /lib/udev/rules.d/73-usb-net-by-mac.rules.

  file {
    '/etc/systemd/network/99-default.link':
      ensure => link,
      target => '/dev/null';
  }
}

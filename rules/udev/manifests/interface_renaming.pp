class udev::interface_renaming {
  # Do not let systemd-udevd mess with interface names, needed by
  # bootservers.

  file {
    '/etc/systemd/network/99-default.link':
      ensure => link,
      target => '/dev/null';
  }
}

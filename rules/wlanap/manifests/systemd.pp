class wlanap::systemd {
  # XXX Our puavo-wlanap does not work without this setting.
  # XXX Do not let systemd change interface names.  Puavo-wlanap should be
  # XXX fixed, but for now, do this.

  file {
    '/etc/systemd/network/99-default.link':
      source => 'puppet:///modules/wlanap/99-default.link';
  }
}

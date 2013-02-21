class udev::udevtrigger_workaround {
  # XXX /etc/init/udevtrigger.conf does not always do its job properly,
  # XXX but some device files (such as /dev/fuse, but there are probably
  # XXX others) will not always have correct permissions after boot.
  # XXX Put a bandaid to /etc/rc.local to try to fix the issues.

  file {
    '/etc/rc.local':
      content => template('udev/rc.local'),
      mode    => 755;
  }
}

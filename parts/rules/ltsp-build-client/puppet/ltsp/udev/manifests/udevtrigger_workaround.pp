class udev::udevtrigger_workaround {
  include dpkg,
    packages

  # XXX The default /etc/init/udevtrigger.conf does not always do its
  # job properly, probably because some of the rule files have been
  # changed or created after udevd has started and becuase inotify does
  # not seem to work properly with overlayfs [1].
  #
  # Symptoms include:
  #   - /dev/fuse has invalid permissions
  #   - Mimio usb device node has invalid permissions
  #
  # Telling udevd to reload rules (/sbin/udevadm control --reload-rules)
  # before triggering buffered kernel events seems to fix the issue.
  #
  # [1]: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/882147

  dpkg::divert {
    '/etc/init/udevtrigger.conf':
      dest => '/etc/init/udevtrigger.conf.dist';
  }

  File {
    require => Package['udev']
  }

  file {
    '/etc/init/udevtrigger.conf':
      content => template('udev/udevtrigger.conf'),
      require => Dpkg::Divert['/etc/init/udevtrigger.conf'];
  }

  Package <| (title == udev) |>
}

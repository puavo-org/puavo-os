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
  # There are also problems with generated udev rules. Again, my guess
  # is that there are problems with inotify+overlayfs -combo: udevd does
  # not realize that generator-rules have generated new rule files and
  # therefore does not use them. The fix is simple: tell udevd to reload
  # rules after writing has finished by calling
  #   /sbin/udevadm control --reload-rules
  # before exit in /lib/udev/write_(net|cd)_rules scripts.
  #
  # [1]: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/882147

  dpkg::divert {
    '/etc/init/udevtrigger.conf':
      dest => '/etc/init/udevtrigger.conf.dist';

    '/lib/udev/write_cd_rules':
      dest => '/lib/udev/write_cd_rules.dist';

    '/lib/udev/write_net_rules':
      dest => '/lib/udev/write_net_rules.dist';
  }

  File {
    require => Package['udev']
  }

  file {
    '/etc/rc.local':
      content => template('udev/rc.local'),
      mode    => '0755';

    '/etc/init/udevtrigger.conf':
      content => template('udev/udevtrigger.conf'),
      require => Dpkg::Divert['/etc/init/udevtrigger.conf'];

    '/lib/udev/write_cd_rules':
      content => template('udev/write_cd_rules'),
      mode    => '0755',
      require => Dpkg::Divert['/lib/udev/write_cd_rules'];

    '/lib/udev/write_net_rules':
      content => template('udev/write_net_rules'),
      mode    => '0755',
      require => Dpkg::Divert['/lib/udev/write_net_rules'];
  }

  Package <| (title == udev) |>
}

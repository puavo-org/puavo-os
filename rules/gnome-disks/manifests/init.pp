class gnome-disks {
  include ::dpkg
  include ::packages

  # XXX remove this for Debian Bookworm that should not need this

  dpkg::simpledivert {
    '/usr/bin/gnome-disks':
      before => File['/usr/bin/gnome-disks'];
  }

  file {
    '/usr/bin/gnome-disks':
      mode   => '0755',
      source => 'puppet:///modules/gnome-disks/gnome-disks';
  }

  Package <| title == gnome-disk-utility |>
}

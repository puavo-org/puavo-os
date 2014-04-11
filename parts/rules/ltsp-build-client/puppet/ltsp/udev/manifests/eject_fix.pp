class udev::eject_fix {
  include dpkg,
    packages

  file {
    '/etc/udev/rules.d/60-eject.rules':
      content => template('udev/60-eject.rules'),
      require => [ Package['eject'], Package['udev'] ];
  }

  Package <| (title == eject)
          or (title == udev) |>
}

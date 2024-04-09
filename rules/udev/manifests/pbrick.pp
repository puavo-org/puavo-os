class udev::pbrick {
  include packages

  file {
    '/etc/udev/rules.d/50-pbrick.rules':
      content => template('udev/50-pbrick.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

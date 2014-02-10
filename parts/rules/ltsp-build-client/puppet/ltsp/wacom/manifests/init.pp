class wacom {
  include packages

  file {
    '/etc/udev/rules.d/60-wacom.rules':
      require => Package['udev'],
      source => 'puppet:///modules/wacom/60-wacom.rules';
  }

  Package <| title == 'udev' |>

}

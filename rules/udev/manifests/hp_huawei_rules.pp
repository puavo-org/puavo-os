class udev::hp_huawei_rules {
  include packages

  # fix suggested in
  # https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1725513

  file {
    '/etc/udev/rules.d/99-hp-huawei-modem.rules':
      content => template('udev/99-hp-huawei-modem.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

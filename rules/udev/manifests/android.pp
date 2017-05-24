class udev::android {
  include packages

  file {
    '/etc/udev/rules.d/51-android.rules':
      content => template('udev/51-android.rules'),
      require => Package['udev'];
  }

  Package <| title == udev |>
}

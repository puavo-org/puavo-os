class woeusb {
  include ::packages

  exec {
    'fetch woeusb':
      command => 'wget -O /usr/local/bin/woeusb.tmp https://raw.githubusercontent.com/WoeUSB/WoeUSB/master/sbin/woeusb && chmod 755 /usr/local/bin/woeusb.tmp && mv /usr/local/bin/woeusb.tmp /usr/local/bin/woeusb',
      creates => '/usr/local/bin/woeusb',
      require => Package['wget'];
  }

  Package <| title == wget |>
}

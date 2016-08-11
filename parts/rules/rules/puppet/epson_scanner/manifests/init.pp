class epson_scanner {
  include packages
  
  file {
    '/lib/udev/rules.d/40-epson-scanner.rules':
      content => template('epson_scanner/udev.rules'),
      require => Package['udev'];
  }

  file {
    '/usr/local/bin/enable_epson_perfection_1650':
      content => template('epson_scanner/enable_epson_perfection_1650'),
      mode    => 755;
  }

  file {
    '/usr/local/bin/disable_epson_perfection_1650':
      content => template('epson_scanner/disable_epson_perfection_1650'),
      mode    => 755;
  }

  Package <| tag == 'tag_libsane' |>
}

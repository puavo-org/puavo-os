class epson_scanner {
  require packages
  
  file {
    '/var/lib/udev/rules.d/40-epson-scanner.rules':
      content => template('epson_scanner/udev.rules');
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

  Package <| tag == epson-scanner |>
}

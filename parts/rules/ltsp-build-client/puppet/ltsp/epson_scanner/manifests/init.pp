class epson_scanner {
  require packages
  
  file {
    '/var/lib/udev/rules.d/40-epson-scanner.rules':
      content => template('epson_scanner/udev.rules');
  }

  Package <| tag == epson-scanner |>
}

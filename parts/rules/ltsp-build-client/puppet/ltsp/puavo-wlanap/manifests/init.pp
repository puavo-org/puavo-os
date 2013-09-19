class puavo-wlanap {
  require packages

  file {
    '/etc/puavo-wlanap/config':
      content => template('puavo-wlanap/config');
  }

  Package <| tag == puavo-wlanap |>
}

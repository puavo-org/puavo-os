class puavo-wlanap {
  require packages

  file {
    '/etc/puavo-wlanap/config':
      content => template('puavo-wlanap/config');
  }

  file {
    '/etc/default/puavo-wlanap':
      content => template('puavo-wlanap/default');
  }

  Package <| tag == puavo-wlanap |>
}

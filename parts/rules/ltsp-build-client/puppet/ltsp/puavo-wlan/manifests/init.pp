class puavo-wlan {
  require packages

  file {
    '/etc/puavo-wlanap/config':
      content => template('puavo-wlan/ap.config');
  }

  file {
    '/etc/default/puavo-wlanap':
      content => template('puavo-wlan/ap.default');
  }

  file {
    '/etc/default/puavo-wlanap-dnsproxy':
      content => template('puavo-wlan/ap-dnsproxy.default');
  }

  Package <| tag == puavo-wlan |>
}

class puavo_wlan {
  require packages

  file {
    '/etc/default/puavo-wlanap':
      content => template('puavo_wlan/ap.default');

    '/etc/default/puavo-wlanap-dnsproxy':
      content => template('puavo_wlan/ap-dnsproxy.default');

    '/etc/puavo-wlanap/config':
      content => template('puavo_wlan/ap.config');
  }

  Package <| title == puavo-wlan
          or title == puavo-wlanap-dnsproxy |>
}

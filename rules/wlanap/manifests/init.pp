class wlanap {
  include ::packages

  service {
    'hostapd':
      enable  => false,
      require => Package['hostapd'];
  }

  Package <| title == hostapd
          or title == puavo-wlanap |>
}

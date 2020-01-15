class wlanap {
  include ::packages

  service {
    'hostapd':
      enable => false;
  }

  Package <| title == puavo-wlanap |>
}

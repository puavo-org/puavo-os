class wlanap {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_wlanap':
      source => 'puppet:///modules/wlanap/setup_wlanap';
  }

  service {
    'hostapd':
      enable  => false,
      require => Package['hostapd'];
  }

  Package <| title == hostapd
          or title == puavo-wlanap |>
}

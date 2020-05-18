class wlanap {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_wlanap':
      source => 'puppet:///modules/wlanap/setup_wlanap';
  }

  Package <| title == puavo-wlanap |>
}

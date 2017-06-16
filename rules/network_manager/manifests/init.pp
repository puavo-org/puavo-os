class network_manager {
  include ::packages

  # Use dns=dnsmasq option so that
  # puavo-vpn-client can work correctly.
  file {
    '/etc/NetworkManager/NetworkManager.conf':
      require => Package['network-manager'],
      source  => 'puppet:///modules/network_manager/NetworkManager.conf';
  }

  Package <| title == network-manager |>
}

class config::vpn {
  $openvpn_remote_servers = ''

  # for example:
  # $openvpn_remote_servers =
  #   sprintf("%s\n%s\n", "192.168.1.199 443 tcp",
  #                       "10.0.0.4      443 tcp")
}

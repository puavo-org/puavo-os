class puavo_openvpn {
  include config::vpn,
          packages

  file {
    '/usr/share/puavo-ltsp/init-puavo.d/90-puavo-openvpn':
      content => template('puavo_openvpn/90-puavo-openvpn'),
      require => Package['puavo-ltsp-client'];
  }

  Package <| title == puavo-ltsp-client |>
}

class network_interfaces {
  include packages

  file {
    '/etc/network/interfaces':
      content => template('network_interfaces/interfaces'),
      require => Package['bridge-utils'];
  }

  Package <| title == "bridge-utils" |>
}

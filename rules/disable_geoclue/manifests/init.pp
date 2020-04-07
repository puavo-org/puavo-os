class disable_geoclue {
  include ::dpkg
  include ::packages

  dpkg::statoverride {
    [ '/usr/lib/geoclue/geoclue-master'
    , '/usr/lib/ubuntu-geoip/ubuntu-geoip-provider' ]:
      owner   => 'root',
      group   => 'root',
      mode    => '0000',
      require => Package['indicator-datetime'];
  }

  # indicator-datetime depends on geoclue and geoclue-ubuntu-geoip,
  # the culprits (these are pointless for us and a privacy issue).
  Package <| title == indicator-datetime |>
}

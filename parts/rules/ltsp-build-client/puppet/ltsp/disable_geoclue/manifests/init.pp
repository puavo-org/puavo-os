class disable_geoclue {
  include dpkg
  require packages

  dpkg::statoverride {
    [ '/usr/lib/geoclue/geoclue-master'
    , '/usr/lib/ubuntu-geoip/ubuntu-geoip-provider' ]:
      owner => 'root',
      group => 'root',
      mode  => 000;
  }

  # indicator-datetime depends on geoclue and geoclue-ubuntu-geoip,
  # the culprits (these are pointless for us and a privacy issue).
  Package <| title == indicator-datetime |>
}

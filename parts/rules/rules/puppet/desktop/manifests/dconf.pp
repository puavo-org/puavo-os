class desktop::dconf {
  include packages

  exec {
    'update dconf':
      command     => '/usr/bin/dconf update',
      refreshonly => true,
      require     => Package['dconf-tools'];
  }

  file {
    [ '/etc/dconf'
    , '/etc/dconf/db'
    , '/etc/dconf/profile' ]:
      ensure => directory;
  }

  Package <| (title == dconf-tools) |>
}

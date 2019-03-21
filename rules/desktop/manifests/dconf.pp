class desktop::dconf {
  include ::packages

  exec {
    'update dconf':
      command     => '/usr/bin/dconf update',
      refreshonly => true,
      require     => Package['dconf-cli'];
  }

  file {
    [ '/etc/dconf'
    , '/etc/dconf/db'
    , '/etc/dconf/profile' ]:
      ensure => directory;
  }

  Package <| (title == dconf-cli) |>
}

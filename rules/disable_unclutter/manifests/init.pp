class disable_unclutter {
  # unclutter gives us problems on some hardware, so make sure that if it
  # is installed, it is *not* started up by default
  include ::packages

  file {
    '/etc/default/unclutter':
      require => Package['unclutter'],
      source  => 'puppet:///modules/disable_unclutter/etc_default_unclutter';
  }

  Package <| title == unclutter |>
}

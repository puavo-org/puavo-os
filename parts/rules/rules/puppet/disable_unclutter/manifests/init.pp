class disable_unclutter {
  # unclutter gives us problems on some hardware, so make sure that if it
  # is installed, it is *not* started up by default

  require packages

  file {
    '/etc/default/unclutter':
      source => 'puppet:///modules/disable_unclutter/etc_default_unclutter';
  }
}

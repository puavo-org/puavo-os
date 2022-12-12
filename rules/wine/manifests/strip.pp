class wine::strip {
  exec {
    # WineHQ packages include quite a bit of debug symbols.
    # Let's clear them up a bit.
    'strip wine-devel binaries':
      command     => '/usr/bin/find /opt/wine-devel/lib* -type f -print0 | xargs -0 strip --strip-unneeded',
      refreshonly => true,
      require     => Package['wine-devel'];
  }
}

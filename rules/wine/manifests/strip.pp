class wine::strip {
  exec { #WineHQ packages include quite a bit of debug symbols. Let's clear them up a bit.
    'strip --strip-unneeded':
      command     => '/usr/bin/find /opt/wine-devel/lib* -type f | xargs strip --strip-unneeded',
      refreshonly => true,
      require     => Package['wine-devel'];
      }
}

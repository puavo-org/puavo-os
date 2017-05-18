class workaround_icedtea_netx_bug {
  # icedtea-netx package sets manually /usr/bin/javaws alternatives link.
  # This package should be fixed, but workaround the problem here in case
  # this package gets installed.

  exec {
    'set javaws alternative to auto':
      command => '/usr/bin/update-alternatives --auto javaws',
      unless  => '/usr/bin/update-alternatives --query javaws | grep -Fqx "Status: auto"';
  }
}

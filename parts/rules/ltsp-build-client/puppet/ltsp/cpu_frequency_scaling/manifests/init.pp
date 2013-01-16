class cpu_frequency_scaling {
  # XXX
  # Disable CPU frequency scaling for now.  Perhaps we will disable this only
  # on some machines, because this is rather drastic.

  file {
    '/etc/init.d/ondemand':
      ensure => absent;
  }
}

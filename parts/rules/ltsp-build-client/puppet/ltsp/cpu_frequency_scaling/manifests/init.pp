class cpu_frequency_scaling {
  file {
    '/etc/init.d/ondemand':
      ensure => absent;
  }
}

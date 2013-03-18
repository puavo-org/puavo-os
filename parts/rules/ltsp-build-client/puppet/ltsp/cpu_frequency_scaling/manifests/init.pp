class cpu_frequency_scaling {
  # XXX
  # Disable CPU frequency scaling for now.  Perhaps we will disable this only
  # on some machines, because this is rather drastic.

  exec {
    '/usr/sbin/update-rc.d -f ondemand disable S 2 3 4 5':
      onlyif => '/usr/bin/test -e /etc/rc2.d/S99ondemand';
  }
}

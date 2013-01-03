class graphics_drivers::fglrx {
  require packages      # require, because ldconfig is run, and all packages
                        # should be installed at this stage

  # XXX TODO!
  exec {
    'setup fglrx alternatives':
      command => '/bin/true',
#      command => '/usr/bin/update-alternatives --set i386-linux-gnu_gl_conf \
#                     /usr/lib/i386-linux-gnu/mesa/ld.so.conf \
#                  && /bin/rm -f x86_64-linux-gnu_gl_conf \
#                  && /sbin/ldconfig \
#                  && /bin/cp -p /etc/ld.so.cache /etc/ld.so.cache-fglrx',
      creates => '/etc/ld.so.cache-fglrx';
      # require => Package['fglrx'];
  }
}

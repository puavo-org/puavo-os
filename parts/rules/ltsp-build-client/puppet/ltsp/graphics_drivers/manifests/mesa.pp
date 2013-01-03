class graphics_drivers::mesa {
  require packages      # require, because ldconfig is run, and all packages
                        # should be installed at this stage

  exec {
    'setup mesa alternatives':
      command => '/usr/bin/update-alternatives --set i386-linux-gnu_gl_conf \
                    /usr/lib/i386-linux-gnu/mesa/ld.so.conf \
                  && /bin/rm -f /etc/alternatives/x86_64-linux-gnu_gl_conf \
                  && /sbin/ldconfig \
                  && /bin/cp -p /etc/ld.so.cache /etc/ld.so.cache-mesa',
      creates => '/etc/ld.so.cache-mesa',
      require => Package['libgl1-mesa-glx'];
  }
}

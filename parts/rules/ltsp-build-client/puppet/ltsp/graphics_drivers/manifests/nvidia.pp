class graphics_drivers::nvidia {
  require packages      # require, because ldconfig is run, and all packages
                        # should be installed at this stage

  exec {
    'setup nvidia alternatives':
      command => '/usr/bin/update-alternatives --set i386-linux-gnu_gl_conf \
                    /usr/lib/nvidia-current/ld.so.conf \
                  && /usr/bin/update-alternatives --set x86_64-linux-gnu_gl_conf \
                        /usr/lib/nvidia-current/alt_ld.so.conf \
                  && /sbin/ldconfig \
                  && /bin/cp -p /etc/ld.so.cache /etc/ld.so.cache-nvidia',
      creates => '/etc/ld.so.cache-nvidia',
      require => [ Package['nvidia-current'], Package['nvidia-settings'], ];
  }
}

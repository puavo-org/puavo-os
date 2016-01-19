class graphics_drivers {
  require packages      # We use "require" here, because things here should be
                        # done only after all packages have been installed,
                        # because we run ldconfig and save its output for
                        # later use.

  $machine = $architecture ? {
               'amd64' => 'x86_64',
               default => $architecture,
             }

  define driver_alternatives ($gl_conf_target) {
    $driver      = $title
    $ld_so_cache = "/etc/ld.so.cache-$driver"

    exec {
      "setup $driver alternatives":
        command =>
          "/usr/bin/update-alternatives \
               --set ${graphics_drivers::machine}-linux-gnu_gl_conf \
                     $gl_conf_target \
             && /sbin/ldconfig \
             && /bin/cp -p /etc/ld.so.cache /etc/ld.so.cache-$driver",
        onlyif =>
          "/usr/bin/test /etc/ld.so.cache-mesa -ot /etc/ld.so.cache";
    }
  }

  case $architecture {
    'amd64', 'i386': {
      driver_alternatives {
       'mesa':
          gl_conf_target
            => "/usr/lib/${machine}-linux-gnu/mesa/ld.so.conf",
          require => [ Driver_alternatives['nvidia']
                     , Package['libgl1-mesa-glx'] ];

       'nvidia':
          before         => File['/etc/modprobe.d/nvidia-304_hybrid.conf'],
          gl_conf_target => '/usr/lib/nvidia-304/ld.so.conf',
          notify         => Driver_alternatives['mesa'],
          require        => [ Package['nvidia-304']
                            , Package['nvidia-settings'] ];
      }

      file {
        # Nouveau must be blacklisted so we can use nvidia,
        # but "alias nouveau off" is a no-no.
        '/etc/modprobe.d/nvidia-304_hybrid.conf':
          content => template('graphics_drivers/blacklist-nouveau.conf');
      }

      Package <| title == libgl1-mesa-glx
              or title == nvidia-304
              or title == nvidia-settings |>
    }
  }
}

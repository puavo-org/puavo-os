class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = [
    'kernel-wedge'      # needed by bpo kernel build

    # systemd and its dependencies from backports so we get ukify
    , 'libnss-myhostname'
    , 'libnss-mymachines'
    , 'libnss-systemd'
    , 'libpam-systemd'
    , 'libsystemd0'
    , 'libsystemd-dev'
    , 'libsystemd0:i386'
    , 'libsystemd-shared'
    , 'libudev1'
    , 'libudev1:i386'
    , 'libudev-dev'
    , 'systemd'
    , 'systemd-boot-efi'
    , 'systemd-container'
    , 'systemd-dev'
    , 'systemd-sysv'
    , 'systemd-timesyncd'
    , 'udev'
  ]
}

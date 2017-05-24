class packages::compat_32bit {
  include ::packages

  # i386-support packages for the amd64-architecture.
  # There are explicit or found-by-trial -dependencies of the following
  # software packages: adobereader-enu, skype, smartboard.
  if $architecture == 'amd64' {
    @package {
      [ 'libasound2:i386'
      , 'libasound2-plugins:i386'
      , 'libbluetooth3:i386'
      , 'libc6:i386'
      , 'libcap-ng0:i386'
      , 'libcurl3:i386'
      , 'libfontconfig1:i386'
      , 'libfreetype6:i386'
      , 'libgcc1:i386'
      , 'libgif7:i386'		# needed by RobboScratch2
      , 'libgl1-mesa-glx:i386'
      , 'libglib2.0-0:i386'
      , 'libgtk2.0-0:i386'
      , 'libice6:i386'
      , 'libjpeg8:i386'		# needed by RobboScratch2
      , 'libltdl7:i386'
      , 'libnspr4-0d:i386'
      , 'libnspr4:i386'
      , 'libnss3:i386'		# needed by RobboScratch2
      , 'libpng12-0:i386'	# needed by GlobiLab
      , 'libpulse0:i386'
      , 'libqt4-dbus:i386'
      , 'libqt4-network:i386'
      , 'libqt4-xml:i386'
      , 'libqtcore4:i386'
      , 'libqtgui4:i386'
      , 'libqtwebkit4:i386'
      , 'libselinux1:i386'
      , 'libsm6:i386'
      , 'libssl1.0.0:i386'
      , 'libstdc++6:i386'
      , 'libudev0:i386'
      , 'libudev1:i386'
      , 'libusb-1.0-0:i386'
      , 'libuuid1:i386'
      , 'libx11-6:i386'
      , 'libxext6:i386'
      , 'libxinerama1:i386'
      , 'libxkbfile1:i386'
      , 'libxml2:i386'
      , 'libxrender1:i386'
      , 'libxslt1.1:i386'
      , 'libxss1:i386'
      , 'libxtst6:i386'
      , 'libxv1:i386'
      , 'zlib1g:i386' ]:
        ensure => present,
        tag    => [ 'tag_debian', 'tag_i386' ];
    }

    # XXX libnss-extrausers:i386 can not live with libnss-extrausers:amd64,
    # XXX the package multiarch-support should be updated.  But this hack
    # XXX does the trick:
    file {
      '/usr/lib/i386-linux-gnu/libnss_extrausers.so.2':
        ensure  => link,
        require => Package['libnss-extrausers'],
        target  => '/usr/lib32/libnss_extrausers.so.2';

      '/usr/lib/x86_64-linux-gnu/libnss_extrausers.so.2':
        ensure  => link,
        require => Package['libnss-extrausers'],
        target  => '/usr/lib/libnss_extrausers.so.2';
    }

    Package <| title == libnss-extrausers |>
  }
}

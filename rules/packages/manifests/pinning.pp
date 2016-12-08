class packages::pinning {
  define for_packages ($packagelist, $target_release, $priority=995) {
    $filename = $title

    file {
      "/etc/apt/preferences.d/${filename}.pref":
        content =>
          sprintf("%s%s%s",
                  inline_template("Package: <%= @packagelist.join(' ') %>\n"),
                  "Pin: release a=${target_release}\n",
                  "Pin-Priority: ${priority}\n");
    }
  }

  if $debianversioncodename != 'jessie' {
    ::packages::pinning::for_packages {
      # nvidia driver 304.132 has OpenGL issues, downgrade
      'nvidia-304':
        packagelist    => [ 'libgl1-nvidia-legacy-304xx-glx'
                          , 'libnvidia-legacy-304xx-cfg1'
                          , 'libnvidia-legacy-304xx-glcore'
                          , 'libnvidia-legacy-304xx-ml1'
                          , 'nvidia-legacy-304xx-alternative'
                          , 'nvidia-legacy-304xx-driver'
                          , 'nvidia-legacy-304xx-driver-bin'
                          , 'nvidia-legacy-304xx-driver-libs'
                          , 'nvidia-legacy-304xx-driver-libs-i386'
                          , 'nvidia-legacy-304xx-kernel-dkms'
                          , 'nvidia-legacy-304xx-kernel-support'
                          , 'nvidia-legacy-304xx-vdpau-driver'
                          , 'nvidia-settings-legacy-304xx'
                          , 'xserver-xorg-video-nvidia-legacy-304xx' ],
        priority       => 1000,
        target_release => 'jessie';
    }
  }
}

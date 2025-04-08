class image::exam {
  include ::apt::no_install_recommends
  include ::exammode::standalone
  include ::initramfs
  include ::kernels
  include ::packages
  include ::plymouth

  Package <|
       tag   == 'tag_firmware_free'
    or tag   == 'tag_firmware_nonfree'
    or tag   == 'tag_kernel'
    or title == 'gnome-keyring'
    or title == 'network-manager'
    or title == 'plocate'
    or title == 'plymouth-themes'
    or title == 'puavo-conf'
    or title == 'puavo-core'
    or title == 'puavo-exammode'
    or title == 'puavo-pam'
    or title == 'puavo-pkg'
    or title == 'wpasupplicant'
    or title == 'xserver-xorg-core'
    or title == 'xserver-xorg-input-all'
    or title == 'xserver-xorg-video-all'
  |>

  ::plymouth::set_default_theme {
    'spinfinity':
      require => Package['plymouth-themes'];
  }

  Packages::Kernels::Kernel_package <| title == 'default' |>
}

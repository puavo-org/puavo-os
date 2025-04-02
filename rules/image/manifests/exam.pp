class image::exam {
  include ::apt::no_install_recommends
  include ::exammode::standalone
  include ::initramfs
  include ::kernels
  include ::packages

  Package <|
       tag   == 'tag_firmware_free'
    or tag   == 'tag_firmware_nonfree'
    or tag   == 'tag_kernel'
    or title == 'network-manager'
    or title == 'plocate'
    or title == 'puavo-conf'
    or title == 'puavo-core'
    or title == 'puavo-exammode'
    or title == 'puavo-pam'
    or title == 'puavo-pkg'
  |>
}

class image::exam {
  include ::exammode::standalone
  include ::initramfs
  include ::kernels
  include ::packages

  Package <|
       tag   == 'tag_kernel'
    or title == 'plocate'
    or title == 'puavo-conf'
    or title == 'puavo-core'
    or title == 'puavo-exammode'
    or title == 'puavo-pam'
    or title == 'puavo-pkg'
  |>
}

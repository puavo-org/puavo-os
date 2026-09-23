class image::bundle::core {
  include ::dracut
  include ::kernels
  include ::locales
  include ::packages
  include ::systemd

  Package <|
       tag   == 'tag_firmware_free'
    or tag   == 'tag_firmware_nonfree'
    or tag   == 'tag_kernel'
    or title == 'plocate'
    or title == 'puavo-conf'
    or title == 'puavo-core'
    or title == 'puavo-pam'
    or title == 'puavo-pkg'
    or title == 'xserver-xorg-core'
    or title == 'xserver-xorg-input-all'
    or title == 'xserver-xorg-video-all'
  |>

  Kernels::Install_kernel <| title == 'default' |>
}

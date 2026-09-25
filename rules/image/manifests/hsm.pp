class image::hsm {
  include ::apt::no_install_recommends
  include ::image::bundle::core
  include ::packages
  include ::plymouth

  Package <|
       tag   == 'tag_puavo_hsm'
    or title == 'cryptsetup'
    or title == 'efibootmgr'
    or title == 'expect'
    or title == 'fwupd'
    or title == 'jq'
    or title == 'libusb-1.0-0-dev'
    or title == 'openssl'
    or title == 'pcscd'
    or title == 'plymouth-themes'
    or title == 'puavo-kps'
    or title == 'puavo-ltsp-client'
    or title == 'puavo-ltsp-install'
    or title == 'rsync'
    or title == 'ssss'
    or title == 'tpm2-tools'
    or title == 'xxd'
  |>

  ::plymouth::set_default_theme {
    'spinner':
      require => Package['plymouth-themes'];
  }
}

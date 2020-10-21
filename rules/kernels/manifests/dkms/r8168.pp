class kernels::dkms::r8168 {
  include ::packages

  # We want to install this package, but we do not want it to be
  # effective by default, only if r8169 has been blacklisted through
  # a kernel parameter or puavo-conf.
  file {
    '/etc/modprobe.d/r8168-dkms.conf':
      content => "blacklist r8168\n",
      require => Package['r8168-dkms'];
  }

  Package <| title == "r8168-dkms" |>
}

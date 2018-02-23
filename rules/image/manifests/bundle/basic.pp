class image::bundle::basic {
  include ::autopoweroff
  include ::console
  include ::disable_suspend_by_tag
  include ::disable_suspend_on_halt
  include ::disable_suspend_on_nbd_devices
  include ::disable_update_initramfs
  include ::hwquirks
  include ::initramfs
  include ::kernels
  # include ::keyboard_hw_quirks        # XXX do we need this for Debian?
  include ::locales
  include ::nss
  include ::packages
  include ::plymouth
  include ::puavo_shutdown
  include ::rpcgssd
  include ::ssh_client
  include ::sysctl
  include ::syslog
  include ::systemd
  include ::udev
  include ::use_urandom
  include ::zram_configuration

  Package <| title == ltsp-client
          or title == puavo-ltsp-client
          or title == puavo-ltsp-install |>
}

class image::bundle::basic {
  include ::autopoweroff
  include ::console
  include ::devilspie
  include ::disable_suspend_by_tag
  include ::disable_suspend_on_halt
  include ::disable_suspend_on_nbd_devices
  include ::disable_unclutter
  include ::disable_update_initramfs
  include ::gdm
  include ::kernels
  # include ::keyboard_hw_quirks        # XXX do we need this for Debian?
  include ::locales
  include ::packages
  include ::packages::languages::de
  include ::packages::languages::en
  include ::packages::languages::fi
  include ::packages::languages::fr
  include ::packages::languages::sv
  include ::picaxe_udev_rules
  include ::plymouth
  include ::rpcgssd
  include ::ssh_client
  include ::sysctl
  include ::syslog
  include ::udev
  include ::use_urandom
  include ::zram_configuration

  case $debianversioncodename {
    'precise': {
      include packages::sssd_install_workaround
    }
  }

  Package <| title == ltsp-client
          or title == puavo-ltsp-client
          or title == puavo-ltsp-install |>
}

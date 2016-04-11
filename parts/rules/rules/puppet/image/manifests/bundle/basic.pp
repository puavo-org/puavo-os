class image::bundle::basic {
  include autopoweroff,
	  console,
	  disable_suspend_by_tag,
	  disable_suspend_on_halt,
	  disable_suspend_on_nbd_devices,
	  disable_unclutter,
	  # disable_update_notifications, # XXX do we need this for Debian?
	  kernels,
	  # keyboard_hw_quirks,		  # XXX do we need this for Debian?
	  lightdm,
	  # motd,			  # XXX needs fixing for Debian
	  packages,
	  packages::languages::de,
	  packages::languages::en,
	  packages::languages::fi,
	  packages::languages::fr,
	  packages::languages::sv,
	  picaxe_udev_rules,
	  ssh_client,
	  udev,
	  use_urandom

  case $lsbdistcodename {
    'precise': {
      include packages::sssd_install_workaround
    }
  }

  Package <| title == ltsp-client
          or title == puavo-ltsp-client
          or title == puavo-ltsp-install |>
}

class image::bundle::basic {
  include autopoweroff,
	  console,
	  disable_suspend_by_tag,
	  disable_suspend_on_halt,
	  disable_suspend_on_nbd_devices,
	  disable_unclutter,
	  disable_update_notifications,
	  graphics_stack_hacks,
	  kernels,
	  lightdm,
	  motd,
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

class image::bundle::basic {
  include autopoweroff,
	  console,
	  disable_suspend_on_halt,
	  disable_unclutter,
	  disable_update_notifications,
	  kernels,
	  lightdm,
	  motd,
	  packages,
	  ssh_client,
	  udev,
	  use_urandom

  case $lsbdistcodename {
    'precise': {
      include packages::sssd_install_workaround
    }
  }

  Package <| title == puavo-ltsp-client
          or title == puavo-ltsp-install |>
}

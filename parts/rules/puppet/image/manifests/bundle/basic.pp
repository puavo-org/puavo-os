class image::bundle::basic {
  include autopoweroff,
	  console,
	  disable_suspend_on_halt,
	  disable_unclutter,
	  disable_update_notifications,
	  kernels,
	  lightdm,
	  motd,
	  ssh_client,
	  udev,
	  use_urandom

  case $lsbdistcodename {
    'precise': {
      include packages::sssd_install_workaround
    }
  }
}

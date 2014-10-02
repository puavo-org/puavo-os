class image::bundle::basic {
  include autopoweroff,
	  console,
	  disable_suspend_on_halt,
	  disable_unclutter,
	  disable_update_notifications,
	  kernels,
	  lightdm,
	  ltspimage_ssh_server,
	  motd,
	  organisation_adm_users,
	  ssh_client,
	  sudo,
	  udev,
	  use_urandom

  case $lsbdistcodename {
    'precise': {
      include packages::sssd_install_workaround
    }
  }
}

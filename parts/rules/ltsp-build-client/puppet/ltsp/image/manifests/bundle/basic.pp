class image::bundle::basic {
  include apt_ltspbuild_proxy,
	  autopoweroff,
	  console,
	  disable_suspend_on_halt,
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
}

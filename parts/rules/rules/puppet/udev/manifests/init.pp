class udev {
  include udev::udevtrigger_workaround
  include udev::eject_fix
  include udev::unblock_wifi
}

class udev {
  include ::udev::android
  include ::udev::hp_huawei_rules
  include ::udev::interface_renaming
  include ::udev::udevtrigger_workaround
  include ::udev::unblock_wifi
}

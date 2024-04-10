class udev {
  include ::udev::android
  include ::udev::avoid_ac_unplug_sleep
  include ::udev::hidraw
  include ::udev::hp_huawei_rules
  include ::udev::interface_renaming
  include ::udev::microbit
  include ::udev::pasco
  include ::udev::pbrick
  include ::udev::udevtrigger_workaround
  include ::udev::unblock_wifi
  include ::udev::vernier
}

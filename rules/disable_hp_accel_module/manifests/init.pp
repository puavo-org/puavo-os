class disable_hp_accel_module {
  file {
    '/etc/modprobe.d/hp-accel-blacklist.conf':
      content => "blacklist hp_accel\n";
  }
}

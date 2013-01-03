class graphics_drivers {
  include graphics_drivers::fglrx,
          graphics_drivers::mesa,
          graphics_drivers::nvidia

  Exec['setup fglrx alternatives' ] -> Exec['setup mesa alternatives']
  Exec['setup nvidia alternatives'] -> Exec['setup mesa alternatives']
}

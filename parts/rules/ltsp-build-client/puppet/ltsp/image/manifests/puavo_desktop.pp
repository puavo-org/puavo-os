class image::puavo_desktop {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include image::opinsys_desktop
        }
      }
    }
  }
}

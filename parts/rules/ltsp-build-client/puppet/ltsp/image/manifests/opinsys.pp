class image::opinsys {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include image::bundle::opinsys,
		  packages::opinsys
        }
      }
    }
  }
}

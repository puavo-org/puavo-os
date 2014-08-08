class image::opinsysextra {
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

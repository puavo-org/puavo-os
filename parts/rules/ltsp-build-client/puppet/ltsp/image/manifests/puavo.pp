class image::puavo {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
	'trusty': {
	  include image::bundle::basic,
		  packages::puavo
	}
      }
    }
  }
}

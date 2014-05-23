class image::puavo {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
	'trusty': {
	  include desktop,
		  image::bundle::basic,
		  packages::puavo
	}
      }
    }
  }
}

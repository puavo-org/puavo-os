class image::thinclient {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
	  include image::bundle::basic,
		  plymouth_theme,
		  packages::thinclient
        }
      }
    }
  }
}

class image::thinclient {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
	  include image::bundle::basic,
		  ltspimage_plymouth_theme,
		  packages::thinclient
        }
      }
    }
  }
}

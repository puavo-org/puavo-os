class image::opinsysextra {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include google-earth-stable,
		  image::bundle::opinsys,
		  ltspimage_java,
		  packages::opinsysextra
        }
      }
    }
  }
}

class image::opinsysextra {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
	  include chrome,
		  chromium_with_chrome_flash,
		  google-earth-stable,
		  image::bundle::opinsys,
		  ltspimage_java,
		  netflix_with_chrome,
		  packages::opinsysextra
        }
      }
    }
  }
}

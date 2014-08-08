class image::opinsysextra {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include chromium_with_chrome_flash,
		  google-earth-stable,
		  image::bundle::opinsys,
		  ltspimage_java,
		  packages::opinsysextra
        }
      }
    }
  }
}

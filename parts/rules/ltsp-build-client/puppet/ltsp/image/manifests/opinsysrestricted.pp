class image::opinsysrestricted {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include citrix,
		  ebeam,
		  chromium_with_chrome_flash,
		  google-earth-stable,
		  google_talkplugin,
		  image::bundle::opinsys,
		  ltspimage_java,
		  mimio,
		  packages::opinsysrestricted,
		  primus,
		  promethean,
		  smartboard
        }
      }
    }
  }
}

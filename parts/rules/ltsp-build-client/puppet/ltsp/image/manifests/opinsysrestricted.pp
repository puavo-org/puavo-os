class image::opinsysrestricted {
  case $operatingsystem {
    'Ubuntu': {
      case $lsbdistcodename {
        'trusty': {
          include citrix,
		  ebeam,
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

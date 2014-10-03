class image::opinsysrestricted {
  case $operatingsystem {
    'Ubuntu': {
      include chrome,
	      chromium_with_chrome_flash,
	      citrix,
	      ebeam,
	      ekapeli,
	      google-earth-stable,
	      google_talkplugin,
	      image::bundle::opinsys,
	      ltspimage_java,
	      mimio,
	      netflix_with_chrome,
	      packages::opinsysrestricted,
	      primus,
	      promethean,
	      smartboard
    }
  }
}

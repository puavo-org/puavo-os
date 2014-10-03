class image::thinclient {
  case $operatingsystem {
    'Ubuntu': {
      include image::bundle::basic,
	      ltspimage_plymouth_theme,
	      packages::thinclient
    }
  }
}

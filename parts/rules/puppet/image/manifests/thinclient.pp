class image::thinclient {
  case $operatingsystem {
    'Ubuntu': {
      include image::bundle::basic,
	      packages::thinclient
    }
  }
}

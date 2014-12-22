class image::desktop {
  case $operatingsystem {
    'Ubuntu': {
      include image::bundle::desktop,
	      packages::puavo
    }
  }
}

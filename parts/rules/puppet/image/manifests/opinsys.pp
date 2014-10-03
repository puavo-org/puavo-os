class image::opinsys {
  case $operatingsystem {
    'Ubuntu': {
      include image::bundle::opinsys,
	      packages::opinsys
    }
  }
}

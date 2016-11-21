class packages::distribution_tweaks {
  # These packages appear to be missing from Debian versions currently
  # (as of 2016-11-14).

  case $debianversioncodename {
    'jessie': {
      Package <|
           title == 'gtklp'
        or title == 'ogmrip'
        or title == 'pencil2d'
      |> { ensure => absent, }
    }
    default: {
      Package <|
	   title == 'krita'
	or title == 'tellico'
      |> { ensure => absent, }
    }
    default: {}
  }
}

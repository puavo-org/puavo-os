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
    'stretch': {
      Package <|
	   title == 'celestia'
	or title == 'celestia-gnome'
	or title == 'denemo'
	or title == 'krita'
	or title == 'libssl1.0.0:i386'
	or title == 'supertuxkart'
	or title == 'tellico'
      |> { ensure => absent, }
    }
    default: {}
  }
}

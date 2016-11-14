class packages::distribution_tweaks {
  case $debianversioncodename {
    'stretch': {
      # These packages appear to be missing from Debian Stretch currently
      # (as of 2016-11-14).
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

class packages::distribution_tweaks {
  case $debianversioncodename {
    'jessie': {
      Package <|
           title == 'gtklp'
        or title == 'ogmrip'
        or title == 'pencil2d'
      |> { ensure => absent, }
    }
    default: {
      # These packages appear to be missing from Stretch currently
      # (as of 2016-11-21) or there installation problems.

      Package <|
	   title == 'calibre'
	or title == 'krita'
	or title == 'libnspr4-0d'
	or title == 'libnspr4-0d:i386'
	or title == 'myspell-sv-se'
	or title == 'tellico'
      |> { ensure => absent, }
    }
  }
}

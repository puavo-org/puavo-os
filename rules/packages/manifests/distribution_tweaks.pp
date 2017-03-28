class packages::distribution_tweaks {
  # These packages appear to be missing from Stretch currently
  # (as of 2016-11-21) or there installation problems.

  Package <|
       title == 'denemo'	# dependency conflict with chromium, which wins
    or title == 'libnspr4-0d'
    or title == 'libnspr4-0d:i386'
    or title == 'myspell-sv-se'
  |> { ensure => absent, }
}

class packages::distribution_tweaks {
  # These packages appear to be missing from Stretch currently
  # (as of 2016-11-21) or there installation problems.

  Package <|
       title == 'firefox-esr-l10n-sv'
    or title == 'fotowall'
    or title == 'mypaint'
    or title == 'mypaint-data'
    or title == 'python-appindicator'
  |> { ensure => absent, }
}

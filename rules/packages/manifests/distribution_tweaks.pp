class packages::distribution_tweaks {
  # These packages appear to be missing from Stretch currently
  # (as of 2016-11-21) or there installation problems.

  Package <|
       title == 'celestia'
    or title == 'celestia-common-nonfree'
    or title == 'celestia-gnome'
    or title == 'eclipse'
    or title == 'firefox-esr-l10n-sv'
    or title == 'firmware-crystalhd'
    or title == 'fmit'
    or title == 'fotowall'
    or title == 'gksu'
    or title == 'gnome-icon-theme-extras'
    or title == 'gnome-themes-extras'
    or title == 'mandelbulber'
    or title == 'musescore-soundfont-gm'
    or title == 'mypaint'
    or title == 'mypaint-data'
    or title == 'python-appindicator'
    or title == 'ttf-freefont'
  |> { ensure => absent, }
}

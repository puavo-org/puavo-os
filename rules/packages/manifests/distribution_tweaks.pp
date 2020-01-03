class packages::distribution_tweaks {
  # These packages appear to be missing from Stretch currently
  # (as of 2016-11-21) or there installation problems.

  Package <|
       title == 'eclipse'
    or title == 'firmware-crystalhd'
    or title == 'fotowall'
    or title == 'gksu'
    or title == 'gnome-icon-theme-extras'
    or title == 'gnome-themes-extras'
    or title == 'musescore-soundfont-gm'
    or title == 'mypaint'               # XXX can not co-exist with gimp
    or title == 'mypaint-data'          # XXX can not co-exist with gimp
    or title == 'ttf-freefont'
    or title == 'virtualbox'
    or title == 'virtualbox-dkms'
  |> { ensure => absent, }
}

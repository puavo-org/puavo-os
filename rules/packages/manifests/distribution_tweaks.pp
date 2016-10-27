class packages::distribution_tweaks {
  case $debianversioncodename {
    'stretch': {
      # These packages appear to be missing from Debian Stretch currently
      # (as of 2016-09-28).
      Package <|
	   title == 'banshee'
	or title == 'celestia'
	or title == 'celestia-gnome'
	or title == 'denemo'
	or title == 'firmware-ipw2x00'
	or title == 'firmware-ivtv'
	or title == 'fonts-droid'
	or title == 'gnome-mplayer'
	or title == 'gnome-themes-extras'
	or title == 'gstreamer0.10-alsa'
	or title == 'gstreamer0.10-pulseaudio'
	or title == 'icedtea-7-plugin'
	or title == 'idle-python3.4'
	or title == 'indicator-session'
	or title == 'krita'
	or title == 'libmotif4'
	or title == 'libreoffice-presentation-minimizer'
	or title == 'libssl1.0.0:i386'
	or title == 'libxp6'
	or title == 'lsb-core'
	or title == 'lsb-invalid-mta'
	or title == 'openjdk-7-jdk'
	or title == 'openjdk-7-jre'
	or title == 'php5-cli'
	or title == 'php5-sqlite'
	or title == 'pulseaudio-module-x11'
	or title == 'python-gst0.10'
	or title == 'python3-aptdaemon.pkcompat'
	or title == 'realtimebattle'
	or title == 'spe'
	or title == 'supertuxkart'
	or title == 'tellico'
	or title == 'vlc-plugin-pulse'
      |> { ensure => absent, }
    }
    default: {}
  }
}

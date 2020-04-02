class puavo_pkg::packages {
  include ::puavo_pkg
  include ::trusty_libs

  # Not all puavo-pkg packages have been tested with all distribution
  # release versions, so keep track of which packages are intended for
  # which versions (all others should be compatible with all supported
  # versions).
  $stretch_specific_packages = [ 'aseba'
                               , 'musescore-appimage'
                               , 'obsidian-icons' ]
  $buster_specific_packages  = [ 'celestia'
                               , 'eclipse'
                               , 'netbeans'
                               , 'ubuntu-wallpapers' ]

  $available_packages = [ 'abitti-naksu'
                        , 'adobe-flashplugin'
			, 'adobe-pepperflashplugin'
			, 'adobe-reader'
			, 'airtame'
			, 'appinventor'
			, 'arduino-ide'
			, 'arduino-radiohead'
			, 'arduino-tm1637'
			, 'bluegriffon'
			, 'cmaptools'
			, 'cnijfilter2'
			, 'cura-appimage'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'enchanting'
			, 'extra-xkb-symbols'
			, 'firefox'
			, 'flashforge-flashprint'
			, 'geogebra'
			, 'geogebra6'
			, 'globilab'
			, 'google-chrome'
			, 'google-earth'
			, 'idid'
			, 'kojo'
			, 'launcherone'
			, 'mafynetti'
			, 'marvinsketch'
			, 'mattermost-desktop'
			, 'msttcorefonts'
			, 'nightcode'
			, 'ohjelmointi-opetuksessa'
			, 'openscad-nightly'
			, 'processing'
			, 'pycharm'
			, 'robboscratch2'
			, 'robotmeshconnect'
			, 'scratux'
			, 'shotcut'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'teams'
			, 'tela-icon-theme'
			, 'tilitin'
			, 't-lasku'
			, 'unityhub-appimage'
			, 'veracrypt'
			, 'vidyo-client'
			, 'zoom' ]

  @puavo_pkg::install { $available_packages: ; }

  case $debianversioncodename {
    'stretch': { @puavo_pkg::install { $stretch_specific_packages: ; } }
    'buster':  { @puavo_pkg::install { $buster_specific_packages:  ; } }
  }

  # "arduino-tm1637", "arduino-radiohead" and "ohjelmointi-opetuksessa"
  # require "arduino-ide" to be installed first.
  Puavo_pkg::Install['arduino-ide'] {
    before +> [ Puavo_pkg::Install['arduino-radiohead']
              , Puavo_pkg::Install['arduino-tm1637']
              , Puavo_pkg::Install['ohjelmointi-opetuksessa'] ],
  }
}

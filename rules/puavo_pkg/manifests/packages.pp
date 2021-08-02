class puavo_pkg::packages {
  include ::puavo_conf
  include ::puavo_pkg
  include ::trusty_libs

  # list removed puavo-pkg packages here
  ::puavo_conf::definition {
    'puavo-pkg-removed.json':
      source => 'puppet:///modules/puavo_pkg/puavo-pkg-removed.json';
  }

  # Not all puavo-pkg packages have been tested with all distribution
  # release versions, so keep track of which packages are intended for
  # which versions (all others should be compatible with all supported
  # versions).
  $stretch_specific_packages = [ 'aseba'
                               , 'musescore-appimage'
                               , 'obsidian-icons'
                               , 'openscad-nightly' ]
  $buster_specific_packages  = [ 'celestia'
                               , 'eclipse'
                               , 'netbeans'
                               , 'supertuxkart'
                               , 'tela-icon-theme'
                               , 'ubuntu-firmware'
                               , 'ubuntu-wallpapers'
                               , 'vagrant' ]

  $available_packages = [ 'abitti-naksu'
			, 'adobe-reader'
			, 'appinventor'
			, 'arduino-ide'
			, 'arduino-ottodiylib'
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
			, 'novoconnect'
			, 'ohjelmointi-opetuksessa'
			, 'processing'
			, 'pycharm'
			, 'robboscratch'
			, 'robotmeshconnect'
			, 'scratux'
			, 'shotcut'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'teams'
			, 'tilitin'
			, 't-lasku'
			, 'unityhub-appimage'
			, 'veracrypt'
			, 'vidyo-client'
			, 'zoom' ]

  # List some packages here which are available, but probably should be
  # installed only for a very few, and this is why they are not on the above
  # list.
  $other_available_packages = [ 'canon-cque'
                              , 'dragonbox_koulu1'
                              , 'dragonbox_koulu2'
                              , 'gdevelop'
                              , 'kdenlive-appimage'
                              , 'otto-blockly'
                              , 'promethean'
                              , 'prusaslicer'
                              , 'signal-desktop'
                              , 'teamviewer'
                              , 'vscode' ]

  @puavo_pkg::install { $available_packages: ; }

  case $debianversioncodename {
    'stretch': { @puavo_pkg::install { $stretch_specific_packages: ; } }
    'buster':  { @puavo_pkg::install { $buster_specific_packages:  ; } }
  }

  # "arduino-ottodiylib", "arduino-tm1637", "arduino-radiohead" and
  # "ohjelmointi-opetuksessa" require "arduino-ide" to be installed first.
  Puavo_pkg::Install['arduino-ide'] {
    before +> [ Puavo_pkg::Install['arduino-ottodiylib']
              , Puavo_pkg::Install['arduino-radiohead']
              , Puavo_pkg::Install['arduino-tm1637']
              , Puavo_pkg::Install['ohjelmointi-opetuksessa'] ],
  }
}

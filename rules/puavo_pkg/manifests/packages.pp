class puavo_pkg::packages {
  include ::puavo_conf
  include ::puavo_pkg
  include ::trusty_libs

  # list removed puavo-pkg packages here
  ::puavo_conf::definition {
    'puavo-pkg-removed.json':
      source => 'puppet:///modules/puavo_pkg/puavo-pkg-removed.json';
  }

  # List some of the available puavo-pkg packages that we want to
  # install by default.  There may be other puavo-pkg packages available.
  $available_packages = [ 'abitti-naksu'
			, 'appinventor'
			, 'arduino-ide'
			, 'arduino-ottodiylib'
			, 'arduino-radiohead'
			, 'arduino-tm1637'
			, 'bluegriffon'
			, 'celestia'
			, 'cmaptools'
			, 'cnijfilter2'
			, 'cura-appimage'
			, 'dropbox'
			, 'eclipse'
			, 'ekapeli-alku'
			, 'enchanting'
			, 'extra-xkb-symbols'
			, 'filius'
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
			, 'musescore-appimage'
			, 'msttcorefonts'
			, 'netbeans'
			, 'nextcloud-desktop'
			, 'nightcode'
			, 'novoconnect'
                        , 'obsidian-icons'
			, 'ohjelmointi-opetuksessa'
			, 'processing'
			, 'puavo-firmware'
			, 'pycharm'
			, 'robboscratch'
			, 'robotmeshconnect'
			, 'rustdesk'
			, 'schoolstore-ti-widgets'
			, 'scratux'
			, 'shotcut'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'tela-icon-theme'
			, 'tilitin'
			, 't-lasku'
			, 'tmux-plugins-battery'
			, 'ubuntu-wallpapers-bullseye'
			, 'unityhub-appimage'
			, 'veracrypt'
			, 'vstloggerpro'
                        , 'wine-gecko'
                        , 'wine-mono'
			, 'zoom' ]

  @puavo_pkg::install { $available_packages: ; }

  # "arduino-ottodiylib", "arduino-tm1637", "arduino-radiohead" and
  # "ohjelmointi-opetuksessa" require "arduino-ide" to be installed first.
  Puavo_pkg::Install['arduino-ide'] {
    before +> [ Puavo_pkg::Install['arduino-ottodiylib']
              , Puavo_pkg::Install['arduino-radiohead']
              , Puavo_pkg::Install['arduino-tm1637']
              , Puavo_pkg::Install['ohjelmointi-opetuksessa'] ],
  }
}

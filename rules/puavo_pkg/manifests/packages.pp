class puavo_pkg::packages {
  include ::puavo_conf
  include ::puavo_pkg

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
			, 'ekapeli-alku'
			, 'enchanting'
			, 'extra-xkb-symbols'
			, 'filius'
			, 'firefox'
			, 'flashforge-flashprint'
			, 'geogebra'
			, 'geogebra6'
			, 'google-chrome'
			, 'google-earth'
			, 'idid'
			, 'kojo'
			, 'launcherone'
			, 'marvinsketch'
			, 'musescore-appimage'
			, 'msttcorefonts'
			, 'nextcloud-desktop'
			, 'novoconnect'
                        , 'obsidian-icons'
			, 'ohjelmointi-opetuksessa'
			, 'puavo-firmware'
			, 'rustdesk'
			, 'schoolstore-ti-widgets'
			, 'scratux'
			, 'shotcut'
			, 'skype'
			, 'spotify-client'
			, 'tela-icon-theme'
			, 'tilitin'
			, 't-lasku'
			, 'tmux-plugins-battery'
			, 'ubuntu-trusty-libs'
			, 'ubuntu-wallpapers-bullseye'
			, 'veracrypt'
                        , 'wine-gecko'
                        , 'wine-mono'
                        , 'xournalpp' ]

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

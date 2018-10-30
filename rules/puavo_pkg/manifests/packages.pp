class puavo_pkg::packages {
  include ::puavo_pkg
  include ::trusty_libs

  # NOTE! adobe-flashplugin and adobe-pepperflashplugin contain both
  # 32-bit and 64-bit versions
  # ("adobe-flashplugin" vs "adobe-flashplugin-32bit",
  # and "adobe-pepperflashplugin" vs. "adobe-pepperflashplugin-32bit").
  # The 32-bit and 64-bit versions can NOT currently co-exist in the same
  # system (silently problems will ensue), so pick the required ones here.
  $available_packages = [ 'adobe-flashplugin-32bit'     # for 32-bit Firefox
			, 'adobe-pepperflashplugin'     # for 64-bit Chromium
			, 'adobe-reader'
			, 'appinventor'
			, 'arduino-ide'
			, 'arduino-radiohead'
			, 'arduino-TM1637'
			, 'bluegriffon'
			, 'cmaptools'
			, 'cnijfilter2'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'enchanting'
			, 'extra-xkb-symbols'
			, 'geogebra'
			, 'geogebra6'
			, 'globilab'
			, 'google-chrome'
			, 'google-earth'
			, 'idid'
			, 'mafynetti'
			, 'marvinsketch'
			, 'mattermost-desktop'
			, 'msttcorefonts'
			, 'obsidian-icons'
			, 'ohjelmointi-opetuksessa'
			, 'oracle-java'
			, 'processing'
			, 'pycharm'
			, 'robboscratch2'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'tilitin'
			, 't-lasku'
			, 'vidyo-client'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }

  # "arduino-TM1637", "arduino-radiohead" and "ohjelmointi-opetuksessa"
  # require "arduino-ide" to be installed first.
  Puavo_pkg::Install['arduino-ide'] {
    before +> [ Puavo_pkg::Install['arduino-TM1637']
              , Puavo_pkg::Install['arduino-radiohead']
              , Puavo_pkg::Install['ohjelmointi-opetuksessa'] ],
  }

  Puavo_pkg::Install['vstloggerpro'] {
    require +> [ ::Trusty_libs::Deb_unpack['x64_64-linux-gnu/libcairomm-1.0.so.1']
               , ::Trusty_libs::Deb_unpack['x64_64-linux-gnu/libglibmm-2.4.so.1']
               , ::Trusty_libs::Deb_unpack['x64_64-linux-gnu/libgtkmm-2.4.so.1'] ],
  }
}

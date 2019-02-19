class puavo_pkg::packages {
  include ::puavo_pkg
  include ::puavo_pkg::ekapeli
  # include ::puavo_pkg::mimio  # XXX do not install this yet
  include ::trusty_libs

  # NOTE! adobe-flashplugin and adobe-pepperflashplugin contain both
  # 32-bit and 64-bit versions
  # ("adobe-flashplugin" vs "adobe-flashplugin-32bit",
  # and "adobe-pepperflashplugin" vs. "adobe-pepperflashplugin-32bit").
  # The 32-bit and 64-bit versions can NOT currently co-exist in the same
  # system (silently problems will ensue), so pick the required ones here.
  $available_packages = [ 'abitti-naksu'
                        , 'adobe-flashplugin-32bit'     # for 32-bit Firefox
			, 'adobe-pepperflashplugin'     # for 64-bit Chromium
			, 'adobe-reader'
			, 'airtame'
			, 'appinventor'
			, 'arduino-ide'
			, 'arduino-radiohead'
			, 'arduino-TM1637'
			, 'av4kav'
			, 'bluegriffon'
			, 'cmaptools'
			, 'cnijfilter2'
			, 'cura-appimage'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'enchanting'
			, 'extra-xkb-symbols'
			, 'flashforge-flashprint'
			, 'geogebra'
			, 'geogebra6'
			, 'globilab'
			, 'google-chrome'
			, 'google-earth'
			, 'idid'
			, 'kojo'
			, 'mafynetti'
			, 'marvinsketch'
			, 'mattermost-desktop'
			, 'msttcorefonts'
			, 'nightcode'
			, 'obsidian-icons'
			, 'ohjelmointi-opetuksessa'
			, 'openscad-nightly'
			, 'oracle-java'
			, 'processing'
			, 'pycharm'
			, 'robboscratch2'
			, 'robotmeshconnect'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'teddybear'
			, 'tilitin'
			, 'ti-nspire-cx-cas-ss'
			, 't-lasku'
			, 'vidyo-client'
			, 'vmware-horizon-client'
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

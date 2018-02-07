class puavo_pkg::packages {
  include ::puavo_pkg
  include ::puavo_pkg::ekapeli

  $available_packages = [ 'adobe-flashplugin'
			, 'adobe-pepperflashplugin'
			, 'adobe-reader'
			, 'appinventor'
			, 'bluegriffon'
			, 'cmaptools'
			, 'cnijfilter2'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'enchanting'
			, 'geogebra'
			, 'globilab'
			, 'google-chrome'
			, 'google-earth'
			, 'marvinsketch'
			, 'mattermost-desktop'
			, 'msttcorefonts'
			, 'obsidian-icons'
			, 'oracle-java'
			, 'processing'
			, 'pycharm'
			, 'robboscratch2'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'tilitin'
			, 'ti-nspire-cx-cas-ss'
			, 't-lasku'
			, 'vidyo-client'
			, 'vmware-horizon-client'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }
}

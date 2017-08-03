class puavo_pkg::packages {
  include ::puavo_pkg
  include ::puavo_pkg::ekapeli

  $available_packages = [ 'adobe-flashplugin'
			, 'adobe-pepperflashplugin'
			, 'adobe-reader'
			, 'appinventor'
			, 'bluegriffon'
			, 'cmaptools'
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
			, 'oracle-java'
			, 'processing'
			, 'pycharm'
			, 'robboscratch2'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'tilitin'
			, 't-lasku'
			, 'vstloggerpro'
			, 'vidyo-client' ]

  @puavo_pkg::install { $available_packages: ; }
}

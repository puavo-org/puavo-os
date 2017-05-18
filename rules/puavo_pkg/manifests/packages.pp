class puavo_pkg::packages {
  include ::puavo_pkg

  $available_packages = [ 'adobe-flashplugin'
			, 'adobe-pepperflashplugin'
			, 'adobe-reader'
			, 'bluegriffon'
			, 'cmaptools'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'enchanting'
			, 'geogebra'
			, 'globilab'
			, 'google-chrome'
			, 'google-earth'
			, 'mattermost-desktop'
			, 'msttcorefonts'
			, 'oracle-java'
			, 'processing'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'tilitin'
			, 't-lasku'
			, 'vstloggerpro'
			, 'vidyo-client' ]

  @puavo_pkg::install { $available_packages: ; }
}

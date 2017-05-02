class puavo_pkg::packages {
  include ::puavo_pkg

  $available_packages = [ 'adobe-flashplugin'
			, 'adobe-pepperflashplugin'
			# , 'adobe-reader'      # XXX old, broken software
			, 'cmaptools'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'geogebra'
			, 'google-chrome'
			, 'google-earth'
			, 'msttcorefonts'
			, 'oracle-java'
			, 'skype'
			, 'smartboard'
			, 'spotify-client'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }
}

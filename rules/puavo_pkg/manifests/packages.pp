class puavo_pkg::packages {
  include puavo_pkg

  $available_packages = [ 'adobe-flashplugin'
			, 'adobe-reader'
			, 'cmaptools'
			, 'dropbox'
			, 'geogebra'
			, 'google-chrome'
			, 'google-earth'
			, 'msttcorefonts'
			, 'oracle-java'
			, 'skype'
			, 'spotify-client'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }
}

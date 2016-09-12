class puavo_pkg::packages {
  include puavo_pkg

  $available_packages = [ 'adobe-flashplugin'
			# , 'adobe-reader'	# no 64-bit version
			, 'cmaptools'
			, 'dropbox'
			, 'geogebra'
			, 'google-chrome'
			, 'google-earth'
			, 'msttcorefonts'
			, 'oracle-java'
			# , 'skype'		# no 64-bit version
			, 'spotify-client'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }
}

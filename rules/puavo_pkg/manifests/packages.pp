class puavo_pkg::packages {
  include ::puavo_pkg

  $available_packages = [ 'adobe-flashplugin'
			, 'adobe-pepperflashplugin'
			, 'adobe-reader'
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
			, 't-lasku'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }

  # Ekapeli is Opinsys-only because the upstream files are not downloadable
  # without the Ekapeli application and its UI, so we keep the upstream pack
  # in our own repository.  (Or are they downloadable?  How?)
  $opinsys_only_packages = [ 'ekapeli' ]
  @puavo_pkg::install { $opinsys_only_packages: ; }
}

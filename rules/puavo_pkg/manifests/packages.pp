class puavo_pkg::packages {
  include puavo_pkg

  $available_packages = [ 'adobe-flashplugin'
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
			, 'spotify-client'
			, 'vstloggerpro' ]

  @puavo_pkg::install { $available_packages: ; }

  # Downloading cmaptools might take a longer time.
  # Some cache for these might be nice... ?
  Puavo_Pkg::Install <| title == 'cmaptools' |> { timeout => 1800, }
}

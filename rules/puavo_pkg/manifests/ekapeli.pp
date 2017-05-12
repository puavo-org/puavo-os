class puavo_pkg::ekapeli {
  include ::fuse
  include ::puavo_pkg

  # Ekapeli is Opinsys-only because the upstream files are not downloadable
  # without the Ekapeli application and its UI, so we keep the upstream pack
  # in our own repository.  (Or are they downloadable?  How?)
  @puavo_pkg::install {
    'ekapeli':
      require => [ File['/etc/fuse.conf']	# needed by special fuse-tricks
		 , Puavo_pkg::Install['oracle-java'] ];
  }
}

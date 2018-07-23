class puavo_pkg::mimio {
  include ::puavo_pkg

  # Mimio is Opinsys-only because the upstream deb-package is old and not
  # downloadable from a public URL anymore.
  @puavo_pkg::install {
    'mimio-studio':
      require => [
        ::Trusty_libs::Deb_unpack['i386-linux-gnu/libgdkmm-2.4.so.1'],
        ::Trusty_libs::Deb_unpack['i386-linux-gnu/libgiomm-2.4.so.1'],
        ::Trusty_libs::Deb_unpack['i386-linux-gnu/libglibmm-2.4.so.1'],
        ::Trusty_libs::Deb_unpack['i386-linux-gnu/libgtkmm-2.4.so.1'], ],
  }
}

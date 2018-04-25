class wine {
  include ::packages

  file {
    '/usr/share/applications/wine.desktop':
      ensure  => link,
      require => Package['wine'],
      target  => '/usr/share/doc/wine/examples/wine.desktop';
  }
}

class wine {
  include ::packages
  include ::wine::setup
  include ::wine::use_wine_devel_as_default

  file {
    '/usr/share/applications/wine.desktop':
      ensure  => link,
      require => Package['wine'],
      target  => '/usr/share/doc/wine/examples/wine.desktop';
  }

  Package <| title == 'wine' |>
}

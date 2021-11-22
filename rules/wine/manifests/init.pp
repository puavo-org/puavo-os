class wine {
  include ::packages
  include ::wine::setup

  file {
    '/usr/share/applications/wine.desktop':
      ensure  => link,
      require => Package['wine'],
      target  => '/usr/share/doc/wine/examples/wine.desktop';
  }

  Package <| title == 'wine' |>
}

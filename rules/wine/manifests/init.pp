class wine {
  include ::packages
  include ::wine::setup

  file {
    '/usr/share/applications/wine.desktop':
      ensure  => link,
      require => Package['wine-devel'],
      target  => '/usr/share/doc/wine/examples/wine.desktop';
  }

  file {
    '/usr/bin/wine-development':
      ensure  => link,
      require => Package['wine-devel'],
      target  => '/usr/bin/wine';
  }

  Package <| title == 'wine' |>
}

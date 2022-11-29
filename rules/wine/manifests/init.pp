class wine {
  include ::packages
  include ::wine::setup
  include ::wine::strip

  file {
    '/usr/share/applications/wine.desktop':
      ensure  => link,
      require => Package['wine-devel'],
      target  => '/opt/wine-devel/share/applications/wine.desktop';
  }

  file {
    '/usr/bin/wine-development':
      require => Package['wine-devel'],
      mode    => '0755',
      source  => 'puppet:///modules/wine/wine-launcher';
  }

  file {
    '/usr/bin/wine-stable':
      require => Package['wine-devel'],
      mode    => '0755',
      source  => 'puppet:///modules/wine/wine-launcher';
  }

  Package <| title == 'wine' |>
}

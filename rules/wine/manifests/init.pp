class wine {
  include ::apt::winehq
  include ::packages
  include ::packages::compat_32bit
  include ::wine::setup
  include ::wine::strip

  $wine_version = $apt::winehq::wine_version;

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

  Package <|
       title == "wine-devel"
    or title == "wine-devel-amd64"
    or title == "wine-devel-i386:i386"
    or title == "winehq-devel"
  |> { ensure => $wine_version }

  Package <| title == 'wine' |>
}

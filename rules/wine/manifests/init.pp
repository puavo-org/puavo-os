class wine {
  include ::packages
  include ::wine::setup
  include ::wine::strip
  $wine_version = '8.0~rc1~bullseye-1'

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
    or title == "winehq-devel"
  |> { ensure => $wine_version }

  Package <| title == 'wine' |>
}

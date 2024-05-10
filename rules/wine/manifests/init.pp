class wine {
  include ::packages
  include ::packages::compat_32bit
  include ::wine::setup
  include ::wine::strip

  file {
    '/usr/bin/wine-development':
      require => Package['wine-devel'],
      mode    => '0755',
      source  => 'puppet:///modules/wine/wine-launcher';

    '/usr/bin/wine-stable':
      require => Package['wine-devel'],
      mode    => '0755',
      source  => 'puppet:///modules/wine/wine-launcher';

    '/usr/share/applications/wine.desktop':
      ensure  => link,
      require => Package['wine-devel'],
      target  => '/opt/wine-devel/share/applications/wine.desktop';
  }

  Package <| title == 'winehq-devel' |>
}

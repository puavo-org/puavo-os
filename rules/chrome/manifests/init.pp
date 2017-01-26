class chrome {
  include ::dpkg
  include ::packages

  dpkg::simpledivert { '/usr/bin/google-chrome-stable': ; }

  file {
    # disable this (does no harm if Chrome is not installed)
    '/etc/apt/sources.list.d/google-chrome.list':
      source => 'puppet:///modules/chrome/google-chrome.list';

    '/usr/bin/google-chrome-stable':
      mode    => '0755',
      require => Dpkg::Simpledivert['/usr/bin/google-chrome-stable'],
      source  => 'puppet:///modules/chrome/google-chrome-stable';
  }
}

class chrome {
  include dpkg,
          packages

  dpkg::simpledivert { '/usr/bin/google-chrome-stable': ; }

  file {
    '/etc/apt/sources.list.d/google-chrome.list':
      require => Package['google-chrome-stable'],
      source  => 'puppet:///modules/chrome/google-chrome.list';

    '/usr/bin/google-chrome-stable':
      mode   => 755,
      source => 'puppet:///modules/chrome/google-chrome-stable';
  }
}

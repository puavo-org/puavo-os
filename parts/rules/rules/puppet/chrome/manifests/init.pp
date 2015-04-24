class chrome {
  include packages

  file {
    '/etc/apt/sources.list.d/google-chrome.list':
      require => Package['google-chrome-stable'],
      source  => 'puppet:///modules/chrome/google-chrome.list';
  }
}

class chrome {
  include packages

  file {
    '/etc/apt/sources.list.d/google-chrome-beta.list':
      require => Package['google-chrome-beta'],
      source  => 'puppet:///modules/chrome/google-chrome-beta.list';

    '/etc/apt/sources.list.d/google-chrome.list':
      require => Package['google-chrome-beta'],
      source  => 'puppet:///modules/chrome/google-chrome.list';
  }
}

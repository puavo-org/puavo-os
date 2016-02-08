class chromium {
  include dpkg,
          packages

  dpkg::simpledivert { '/usr/bin/chromium-browser': ; }

  file {
    '/etc/chromium-browser/default':
      source  => 'puppet:///modules/chromium/etc_chromium_browser_default',
      require => [ Package['chromium'] ];

    '/usr/bin/chromium-browser':
      mode   => 755,
      source => 'puppet:///modules/chromium/chromium-browser';
  }

  Package <| title == chromium |>
}

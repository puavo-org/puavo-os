class chromium {
  include packages

  file {
    '/etc/chromium-browser/default':
      source  => 'puppet:///modules/chromium/etc_chromium_browser_default',
      require => [ Package['chromium-browser'] ];
  }

  Package <| title == chromium-browser |>
}

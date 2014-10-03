class chromium_with_chrome_flash {
  include packages

  file {
    '/etc/chromium-browser/default':
      source  => 'puppet:///modules/chromium_with_chrome_flash/etc_chromium_browser_default',
      require => [ Package['chromium-browser']
                 , Package['google-chrome-stable'] ];
  }

  Package <| title == chromium-browser
          or title == google-chrome-stable |>
}

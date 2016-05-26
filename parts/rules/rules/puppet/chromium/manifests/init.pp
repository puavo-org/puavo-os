class chromium {
  include dpkg,
          packages

  dpkg::simpledivert { '/usr/bin/chromium': ; }

  file {
    '/usr/bin/chromium':
      mode   => 755,
      source => 'puppet:///modules/chromium/chromium';
  }

  Package <| title == chromium |>
}

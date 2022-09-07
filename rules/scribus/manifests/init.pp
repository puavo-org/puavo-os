class scribus {
  include ::dpkg
  include ::packages

  dpkg::simpledivert {
    '/usr/bin/scribus':
      before => File['/usr/bin/scribus'];
  }

  file {
    '/usr/bin/scribus':
      mode   => '0755',
      source => 'puppet:///modules/scribus/scribus';
  }

  Package <| title == scribus |>
}

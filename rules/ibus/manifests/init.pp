class ibus {
  include ::packages

  file {
    '/usr/local/bin/puavo-ibus':
      content => 'puppet:///modules/ibus/puavo-ibus',
      require => Package['ibus-anthy'];
  }

  Package <| title == ibus-anthy |>
}

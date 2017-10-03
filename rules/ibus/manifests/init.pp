class ibus {
  include ::packages

  file {
    '/usr/local/bin/puavo-ibus':
      content => 'puppet:///modules/ibus/puavo-ibus',
      mode    => '0755',
      require => Package['ibus-anthy'];
  }

  Package <| title == ibus-anthy |>
}

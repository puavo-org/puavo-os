class ibus {
  include ::packages

  file {
    '/usr/local/bin/puavo-ibus':
      mode    => '0755',
      require => Package['ibus-anthy'],
      source  => 'puppet:///modules/ibus/puavo-ibus';
  }

  Package <| title == ibus-anthy |>
}

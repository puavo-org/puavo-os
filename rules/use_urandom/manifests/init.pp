class use_urandom {
  include ::packages

  file {
    '/etc/default/rng-tools-debian':
      content => template('use_urandom/rng-tools-debian'),
      require => Package['rng-tools-debian'];
  }

  Package <| title == rng-tools-debian |>
}

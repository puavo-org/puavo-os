class use_urandom {
  include ::packages

  file {
    '/etc/default/rng-tools':
      content => template('use_urandom/rng-tools'),
      require => Package['rng-tools'];
  }

  Package <| title == rng-tools |>
}

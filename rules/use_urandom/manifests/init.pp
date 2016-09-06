class use_urandom {
  require packages

  file {
    '/etc/default/rng-tools':
      content => template('use_urandom/rng-tools');
  }

  Package <| title == rng-tools |>
}

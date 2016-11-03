class google-earth-stable {
  include ::packages

  file {
    '/etc/default/google-earth':
      ensure => present,
      before => Package['google-earth-stable'];
  }

  Package <| title == google-earth-stable |>
}

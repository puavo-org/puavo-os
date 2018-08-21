class blueman {
  include ::packages

  file {
    '/etc/xdg/autostart/blueman.desktop':
      ensure  => absent,
      require => Package['blueman'];
  }

  Package <| title == blueman |>
}

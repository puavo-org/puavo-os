class desktop::enable_indicator_power_service {
  include ::packages

  file {
    '/etc/xdg/autostart/indicator-power.desktop':
      content => template('desktop/indicator-power.desktop'),
      require => Package['indicator-power'];
  }

  Package <| title == indicator-power |>
}

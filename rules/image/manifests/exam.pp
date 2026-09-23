class image::exam {
  include ::apt::no_install_recommends
  include ::exammode::standalone
  include ::image::bundle::core
  include ::packages
  include ::plymouth

  Package <|
       title == 'gnome-keyring'
    or title == 'network-manager'
    or title == 'puavo-exammode'
    or title == 'plymouth-themes'
    or title == 'wpasupplicant'
  |>

  ::plymouth::set_default_theme {
    'spinner':
      require => Package['plymouth-themes'];
  }
}

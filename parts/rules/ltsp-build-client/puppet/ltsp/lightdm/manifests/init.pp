class lightdm {
  include packages

  file {
    '/etc/lightdm/lightdm-gtk-greeter-ubuntu.conf':
      content => template('lightdm/lightdm-gtk-greeter-ubuntu.conf'),
      require => Package['lightdm'];
  }

  Package <| title == lightdm |>
}

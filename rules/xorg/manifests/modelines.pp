class xorg::modelines {
  file {
    '/usr/share/X11/xorg.conf.d/50-puavo-modelines.conf':
      content => template('xorg/50-puavo-modelines.conf'),
      require => Package['xorg'];
  }

  Package <| title == xorg |>
}

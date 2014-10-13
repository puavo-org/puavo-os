class tuxpaint {
  include packages

  file {
    '/etc/tuxpaint/tuxpaint.conf':
      content => template('tuxpaint/tuxpaint.conf'),
      require => Package['tuxpaint'];
  }

  Package <| title == tuxpaint |>
}

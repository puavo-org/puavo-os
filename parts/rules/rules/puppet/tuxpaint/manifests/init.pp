class tuxpaint {
  include packages

  file {
    '/etc/tuxpaint/tuxpaint.conf':
      content => template('tuxpaint/tuxpaint.conf'),
      require => [ Package['gtklp'], Package['tuxpaint'], ];
  }

  Package <| title == gtklp or title == tuxpaint |>
}

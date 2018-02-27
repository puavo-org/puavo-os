class bootserver_inetd {
  include ::packages

  file {
    '/etc/inetd.conf':
      content => template('bootserver_inetd/inetd.conf'),
      require => Package['openbsd-inetd'];
  }

  Package <| title == openbsd-inetd |>
}

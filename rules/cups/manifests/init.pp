class cups {
  include ::packages

  file {
    '/etc/cups/cupsd.conf':
      require => Package['cups-daemon'],
      source  => 'puppet:///modules/cups/cupsd.conf';
  }

  Package <| title == cups-daemon |>
}

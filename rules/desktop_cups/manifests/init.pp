class desktop_cups {
  include ::packages

  file {
    '/etc/cups/cupsd.conf':
      require => Package['cups-daemon'],
      source  => 'puppet:///modules/desktop_cups/cupsd.conf';
  }

  Package <| title == cups-browsed
          or title == cups-daemon |>
}

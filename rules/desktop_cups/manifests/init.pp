class desktop_cups {
  include ::packages

  file {
    '/etc/cups/cups-browsed.conf':
      require => Package['cups-browsed'],
      source  => 'puppet:///modules/desktop_cups/cups-browsed.conf';

    '/etc/cups/cupsd.conf':
      require => Package['cups-daemon'],
      source  => 'puppet:///modules/desktop_cups/cupsd.conf';
  }

  Package <| title == cups-browsed
          or title == cups-daemon |>
}

class cups {
  include ::packages

  file {
    '/etc/cups/cups-browsed.conf':
      require => Package['cups-browsed'],
      source  => 'puppet:///modules/cups/cups-browsed.conf';

    '/etc/cups/cupsd.conf':
      require => Package['cups-daemon'],
      source  => 'puppet:///modules/cups/cupsd.conf';
  }

  Package <| title == cups-browsed
          or title == cups-daemon |>
}

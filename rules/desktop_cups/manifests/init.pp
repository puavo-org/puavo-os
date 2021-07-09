class desktop_cups {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/cups/cups-browsed.conf':
      require => Package['cups-browsed'],
      source  => 'puppet:///modules/desktop_cups/cups-browsed.conf';

    '/etc/cups/cupsd.conf':
      require => Package['cups-daemon'],
      source  => 'puppet:///modules/desktop_cups/cupsd.conf';
  }

  ::puavo_conf::script {
    'setup_desktop_printer_restrictions':
      source => 'puppet:///modules/desktop_cups/setup_desktop_printer_restrictions';
  }

  Package <| title == cups-browsed
          or title == cups-daemon |>
}

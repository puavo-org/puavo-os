class bootserver_cups {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_bootserver_cups':
      require => Package['cups'],
      source  => 'puppet:///modules/bootserver_cups/setup_bootserver_cups';

    'setup_bootserver_printer_restrictions':
      require => Package['cups'],
      source  => 'puppet:///modules/bootserver_cups/setup_bootserver_printer_restrictions';
  }

  file {
     '/etc/systemd/system/cups-watchdog.service':
       require => [ File['/usr/local/lib/cups-watchdog']
                  , Package['systemd'] ],
       source  => 'puppet:///modules/bootserver_cups/cups-watchdog.service';

     '/etc/systemd/system/multi-user.target.wants/cups-watchdog.service':
       ensure  => link,
       require => [ File['/etc/systemd/system/cups-watchdog.service']
                  , Package['systemd'] ],
       target  => '/etc/systemd/system/cups-watchdog.service';

     '/usr/local/lib/cups-watchdog':
       mode    => '0755',
       require => Package['cups-client'],
       source  => 'puppet:///modules/bootserver_cups/cups-watchdog';

     '/usr/local/lib/puavo-handle-cups-changes':
       mode    => '0755',
       require => Package['puavo-client'],
       source  => 'puppet:///modules/bootserver_cups/puavo-handle-cups-changes';
  }

  Package <| title == cups
          or title == cups-client
          or title == puavo-client
          or title == systemd |>
}

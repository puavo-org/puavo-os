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
       require => File['/usr/local/lib/cups-watchdog'],
       source  => 'puppet:///modules/bootserver_cups/cups-watchdog.service';

     '/etc/systemd/system/multi-user.target.wants/cups-watchdog.service':
       ensure  => link,
       require => File['/etc/systemd/system/cups-watchdog.service'],
       target  => '/etc/systemd/system/cups-watchdog.service';

     '/usr/local/lib/cups-watchdog':
       mode    => '0755',
       require => Package['cups-client'],
       source  => 'puppet:///modules/bootserver_cups/cups-watchdog';
  }

  Package <| title == cups
          or title == cups-client |>
}

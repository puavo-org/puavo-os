class bootserver_cups {
  include ::packages
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_bootserver_cups':
      require => Package['cups'],
      source  => 'puppet:///modules/bootserver_cups/setup_bootserver_cups';
  }

# XXX cups-watchdog disabled for now
# file {
#    '/etc/init/cups-watchdog.conf':
#      content => template('bootserver_cups/cups-watchdog.upstart'),
#      mode    => '0644',
#      require => File['/usr/local/lib/cups-watchdog'];
#
#    '/etc/init.d/cups-watchdog':
#      ensure  => link,
#      require => File['/etc/init/cups-watchdog.conf'],
#      target  => '/lib/init/upstart-job';
#
#    '/usr/local/lib/cups-watchdog':
#      content => template('bootserver_cups/cups-watchdog'),
#      mode    => '0755';
# }

  Package <| title == cups |>
}

class bootserver_nagios {
  include ::bootserver_config
  include ::nagios

  file {
    '/etc/nagios/nrpe.cfg':
      content => template('bootserver_nagios/nrpe.cfg'),
      notify  => Service['nagios-nrpe-server'];
  }

  Dpkg::Statoverride   <| tag == bootserver |>
  Nagios::Check::Check <| tag == bootserver |>
}

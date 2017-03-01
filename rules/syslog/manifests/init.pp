class syslog {
  include ::packages

  file {
    '/etc/rsyslog.conf':
      require => Package['rsyslog'],
      source  => 'puppet:///modules/syslog/rsyslog.conf';
  }

  Package <| title == rsyslog |>
}

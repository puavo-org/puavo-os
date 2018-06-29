class syslog {
  include ::packages

  file {
    '/etc/rsyslog.conf':
      require => Package['rsyslog'],
      source  => 'puppet:///modules/syslog/rsyslog.conf';

    '/usr/local/lib/puavo-caching-syslog-sender':
      mode    => '0755',
      require => File['/var/log/puavo-os'],
      source  => 'puppet:///modules/syslog/puavo-caching-syslog-sender';

    '/var/log/puavo-os':
      ensure => directory;
  }

  Package <| title == rsyslog |>
}

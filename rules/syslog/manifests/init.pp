class syslog {
  include ::packages

  file {
    '/usr/local/lib/puavo-caching-syslog-sender':
      mode    => '0755',
      require => File['/var/log/puavo-os'],
      source  => 'puppet:///modules/syslog/puavo-caching-syslog-sender';

    '/var/log/puavo-os':
      ensure => directory;
  }

  Package <| title == rsyslog |>
}

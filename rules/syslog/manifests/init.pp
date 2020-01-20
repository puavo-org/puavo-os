class syslog {
  include ::packages

  file {
    '/etc/logrotate.d/martians':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_martians';

    '/etc/logrotate.d/puavo':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_puavo';

    '/usr/local/lib/puavo-caching-syslog-sender':
      mode    => '0755',
      require => [ File['/var/log/puavo'], Package['tcl-thread'] ],
      source  => 'puppet:///modules/syslog/puavo-caching-syslog-sender';

    '/var/log/puavo':
      owner  => 'root',
      group  => 'adm',
      mode   => '0750',
      ensure => directory;
  }

  Package <| title == logrotate
          or title == rsyslog
          or title == tcl-thread |>
}

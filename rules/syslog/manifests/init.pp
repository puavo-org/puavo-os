class syslog {
  include ::packages

  file {
    '/etc/logrotate.d/extras':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_extras';

    '/etc/logrotate.d/martians':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_martians';

    '/etc/logrotate.d/puavo':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_puavo';

    # Run logrotate on battery too (Debian default skips it).
    '/etc/systemd/system/logrotate.service.d':
      ensure  => directory,
      require => Package['systemd'];

    '/etc/systemd/system/logrotate.service.d/override.conf':
      require => [ Package['logrotate'], Package['systemd'] ],
      source  => 'puppet:///modules/syslog/logrotate.service.d_override.conf';

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
          or title == systemd
          or title == tcl-thread |>
}

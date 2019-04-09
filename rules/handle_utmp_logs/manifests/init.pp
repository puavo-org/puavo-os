class handle_utmp_logs {
  include ::puavo_conf

  file {
    '/etc/tmpfiles.d/puavo-utmp-logs.conf':
     source => 'puppet:///modules/handle_utmp_logs/puavo-utmp-logs.conf';
  }

  ::puavo_conf::script {
    'handle_utmp_logs':
     source => 'puppet:///modules/handle_utmp_logs/handle_utmp_logs';
  }
}

class bootserver_slapd {
  include ::packages
  include ::puavo_conf

  # XXX Is this still necessary?  (Should get apparmor working first.)
  File { require => Package['slapd'] }
  file {
    '/etc/apparmor.d/local/usr.sbin.slapd':
      source => 'puppet:///modules/bootserver_slapd/local-apparmor-inclusions';

    '/usr/local/lib/puavo-service-wait-for-slapd':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_slapd/puavo-service-wait-for-slapd';
  }

  ::puavo_conf::script {
    'setup_slapd':
      source => 'puppet:///modules/bootserver_slapd/setup_slapd';
  }

  Package <| title == slapd or title == systemd |>
}

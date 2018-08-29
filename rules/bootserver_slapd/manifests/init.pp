class bootserver_slapd {
  include ::packages
  include ::puavo_conf

  # XXX Is this still necessary?  (Should get apparmor working first.)
  File { require => Package['slapd'] }
  file {
    '/etc/apparmor.d/local/usr.sbin.slapd':
      source => 'puppet:///modules/bootserver_slapd/local-apparmor-inclusions';

    '/etc/systemd/system/slapd.service':
      source => 'puppet:///modules/bootserver_slapd/slapd.service';
  }

  ::puavo_conf::script {
    'setup_slapd':
      source => 'puppet:///modules/bootserver_slapd/setup_slapd';
  }

  Package <| title == slapd |>
}

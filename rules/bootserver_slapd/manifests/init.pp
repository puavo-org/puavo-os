class bootserver_slapd {
  include ::packages
  include ::puavo_conf

  # XXX Is this still necessary?  (Should get apparmor working first.)
  File { require => Package['slapd'] }
  file {
    '/etc/apparmor.d/local/usr.sbin.slapd':
      source => 'puppet:///modules/bootserver_slapd/local-apparmor-inclusions';

    '/etc/default/slapd':
      source => 'puppet:///modules/bootserver_slapd/etc_default_slapd';

    '/etc/init.d/slapd':
      mode   => '0755',
      source => 'puppet:///modules/bootserver_slapd/etc_init.d_slapd';
  }

  ::puavo_conf::script {
    'setup_slapd':
      source => 'puppet:///modules/bootserver_slapd/setup_slapd';
  }

  Package <| title == slapd |>
}

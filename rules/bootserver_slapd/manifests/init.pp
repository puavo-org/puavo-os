class bootserver_slapd {
  # XXX Is this still necessary?  (Should get apparmor working first.)
  file {
    '/etc/apparmor.d/local/usr.sbin.slapd':
      source => 'puppet:///modules/bootserver_slapd/local-apparmor-inclusions';

    '/etc/init.d/slapd':
      source => 'puppet:///modules/bootserver_slapd/etc_init.d_slapd';
  }
}

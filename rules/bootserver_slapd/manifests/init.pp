class bootserver_slapd {
  # XXX Is this still necessary?  (Should get apparmor working first.)
  file {
    '/etc/apparmor.d/local/usr.sbin.slapd':
      source => 'puppet:///modules/bootserver_slapd/local-apparmor-inclusions';
  }
}

class bootserver_slapd {

  exec {
    'apparmor slapd reload':
      command     => '/sbin/apparmor_parser -r /etc/apparmor.d/usr.sbin.slapd',
      refreshonly => true;
  }

  file {
    '/etc/apparmor.d/local/usr.sbin.slapd':
      notify => Exec['apparmor slapd reload'],
      source => 'puppet:///modules/bootserver_slapd/local-apparmor-inclusions';
  }

}

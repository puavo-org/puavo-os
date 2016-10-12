class bootserver_ldap {
  file {
    '/etc/ldap/ldap.conf':
      content => template('bootserver_ldap/ldap.conf');
  }
}

facter_vars = {
  'puavo_domain'              => '/etc/puavo/domain',
  'puavo_hostname'            => '/etc/puavo/hostname',
  'puavo_hosttype'            => '/etc/puavo/hosttype',
  'puavo_kerberos_master'     => '/etc/puavo/kerberos/master',
  'puavo_kerberos_realm'      => '/etc/puavo/kerberos/realm',
  'puavo_kerberos_toprealm'   => '/etc/puavo/kerberos/toprealm',
  'puavo_ldap_base'           => '/etc/puavo/ldap/base',
  'puavo_ldap_dn'             => '/etc/puavo/ldap/dn',
  'puavo_ldap_master'         => '/etc/puavo/ldap/master',

  # XXX This should be okay (we're not using puppetmaster, so password does
  # XXX not get exposed far), but I am not completely sure...
  # XXX these facts are private, are they not?
  'puavo_ldap_password'       => '/etc/puavo/ldap/password',

  'puavo_ldap_slave'          => '/etc/puavo/ldap/slave',
  'puavo_primary_ltsp_server' => '/etc/puavo/primary_ltsp_server',
  'puavo_topdomain'           => '/etc/puavo/topdomain',
}

facter_vars.each do |facter_var, path|
  value = IO.readlines(path).first.chomp rescue nil
  if value then
    Facter.add(facter_var) { setcode { value } }
  end
end

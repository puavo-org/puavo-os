#!/usr/bin/env ruby

def has_content(path)
  File.open(path) { |f| f.read }.size > 0
end

[
  "/etc/puavo/hostname",
  "/etc/puavo/domain",
  "/etc/puavo/host_configuration",
  "/etc/puavo/certs/host.key",
  "/etc/puavo/certs/rootca.pem",
  "/etc/puavo/certs/orgcabundle.pem",
  "/etc/puavo/certs/host.crt",
  "/etc/puavo/ldap/password",
  "/etc/puavo/ldap/base",
  "/etc/puavo/ldap/dn",
  "/etc/puavo/kerberos/realm",
].each do |path|

  if not has_content(path)
    raise "File missing: #{ path }"
  end

end

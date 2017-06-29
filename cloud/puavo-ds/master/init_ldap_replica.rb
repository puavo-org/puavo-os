#!/usr/bin/ruby

require "erb"
require 'tempfile'

@master_server = "ldap://ldap1.example.com"
@rootdn = "uid=admin,o=Puavo"
@rootpw = "password"

`/etc/init.d/slapd stop`
`killall -9 slapd`
`rm -rf /etc/ldap/slapd.d/* /var/lib/ldap/*`
`mkdir -p /var/lib/ldap/o=puavo`

(1..300).each do |num|
  dir = "/var/lib/ldap/db%03d" % num

  `mkdir -p #{dir}`
end

tempfile = Tempfile.open("ldif")
tempfile.close

print `ldapsearch -x -H #{@master_server} -D #{@rootdn} -w #{@rootpw} -b cn=config > #{tempfile.path} -Z`
print `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b cn=config`

tempfile.delete

`chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap`
`chmod -R 0750 /var/lib/ldap`

`/etc/init.d/slapd start`

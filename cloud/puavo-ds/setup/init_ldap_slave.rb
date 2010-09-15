#!/usr/bin/ruby

require "erb"
require 'tempfile'

@master_server = "ldap://ldap1.example.org"
@binddn = "uid=admin,o=Puavo"
@bindpw = "password"
@suffix = "dc=example,dc=edu"

def parse_erb(basename)
  ldif_template = File.read("templates/#{basename}.ldif.erb")
  ldif = ERB.new(ldif_template, 0, "%<>")

  tempfile = Tempfile.open(basename)
  tempfile.puts ldif.result
  tempfile.close
  
  return tempfile
end

`/etc/init.d/slapd stop`
`killall -9 slapd`
`rm -rf /etc/ldap/slapd.d/* /var/lib/ldap/*`

@acls =  `ldapsearch -LLL -x -H #{@master_server} -D #{@binddn} -w #{@bindpw} -Z -b cn=config "(&(objectClass=olcDatabaseConfig)(olcSuffix=#{@suffix}))" olcAccess|grep -v dn:`
@schemas = `ldapsearch -LLL -x -H #{@master_server} -D #{@binddn} -w #{@bindpw} -Z -b cn=schema,cn=config`

tempfile = parse_erb("init_ldap_slave")
puts `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b "cn=config"`

`chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap`
`chmod -R 0750 /var/lib/ldap`

`/etc/init.d/slapd start`

#!/usr/bin/ruby

require "erb"
require 'tempfile'

def parse_erb(basename)
  ldif_template = File.read("templates/#{basename}.ldif.erb")
  ldif = ERB.new(ldif_template, 0, "%<>")

  tempfile = Tempfile.open(basename)
  tempfile.puts ldif.result
  tempfile.close
  
  return tempfile
end

# rootdn is configured as the rootdn for o=Puavo and given manage
# access in cn=config
@rootdn = "uid=admin,o=Puavo"

# TODO: These passwords need to be moved out
@rootpw = "password"
@puppetpw = "password"
@puavopw = "password"

@rootpw_hash=`slappasswd -h "{SSHA}" -s "#{@rootpw}"`.gsub(/\n/,"")
@puavopw_hash=`slappasswd -h "{SSHA}" -s "#{@puavopw}"`.gsub(/\n/,"")
@puppetpw_hash=`slappasswd -h "{SSHA}" -s "#{@puppetpw}"`.gsub(/\n/,"")

# First whole slapd configuration and all data is wiped out

`/etc/init.d/slapd stop`
`killall -9 slapd`
`rm -rf /var/lib/ldap/*`

# AppArmor rules allow slapd to access files under /var/lib/ldap so
# we'll just create new directories under it for different databases:
#
# /var/lib/ldap/o=puavo
# /var/lib/ldap/db001
# /var/lib/ldap/db002
# /var/lib/ldap/db003
# ...

`mkdir -p /var/lib/ldap/o=puavo`

(1..300).each do |num|
  dir = "/var/lib/ldap/db%03d" % num

  `mkdir -p #{dir}`
  `chown openldap.openldap #{dir}`
  `chmod 0750 #{dir}`
end

`cp schema/*.ldif /etc/ldap/schema/`
`rm -rf /etc/ldap/slapd.d/*`

# TODO: move these to the config file

@servers = ["ldap://ldap1.opinsys.fi",
            "ldap://ldap2.opinsys.fi",
            "ldap://ldap3.opinsys.fi"]

`cp certs/slapd-ca.crt /etc/ssl/certs/slapd-ca.crt`
`cp certs/slapd-server.crt /etc/ssl/certs/slapd-server.crt`
`cp certs/slapd-server.key /etc/ssl/certs/slapd-server.key`

`chown root.openldap /etc/ssl/certs/slapd-server.key`
`chown root.openldap /etc/ssl/certs/slapd-server.crt`
`chown root.openldap /etc/ssl/certs/slapd-ca.crt`

# As /etc/ldap/slapd.d is now totally empty, slapd won't start before
# initial config is added with slapadd.
#
# Initialize cn=config from a template ldif file

tempfile = parse_erb("init_ldap")
puts `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b "cn=config"`
tempfile.delete

# Initialize o=puavo from a template ldif file

tempfile = parse_erb("init_puavo_db")
puts `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b "o=Puavo"`
tempfile.delete

# slapdadd leaves the files owner by root, so let's fix those

`chown -R openldap.openldap /etc/ldap/slapd.d`
`chown -R openldap.openldap /var/lib/ldap/o=puavo`
`chmod 0750 /var/lib/ldap/o=puavo`

`/etc/init.d/slapd start`
`sleep 5`

# slapd should be running now and the rest of the modifications
# can be done with ldapmodify. This includes settings ACLs and
# syncrepl replication.

["set_global_acl",
 "set_syncrepl_settings",
 "set_puavo_syncrepl_settings"].each do |basename|

  ldif_template = File.read("templates/#{basename}.ldif.erb")
  ldif = ERB.new(ldif_template, 0, "%<>")

  tempfile = Tempfile.open(basename)
  tempfile.puts ldif.result
  tempfile.close

  puts `cat #{tempfile.path}`
  puts `ldapmodify -Y EXTERNAL -H ldapi:/// -f #{tempfile.path} 2>&1`

  tempfile.delete
end

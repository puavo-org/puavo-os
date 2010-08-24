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

@rootdn = "uid=admin,o=Puavo"
@rootpw = "password"
@puppetpw = "password"
@puavopw = "password"

@rootpw_hash=`slappasswd -h "{SSHA}" -s "#{@rootpw}"`.gsub(/\n/,"")
@puavopw_hash=`slappasswd -h "{SSHA}" -s "#{@puavopw}"`.gsub(/\n/,"")
@puppetpw_hash=`slappasswd -h "{SSHA}" -s "#{@puppetpw}"`.gsub(/\n/,"")

`/etc/init.d/slapd stop`
`killall -9 slapd`
`rm -rf /var/lib/ldap/*`
`mkdir -p /var/lib/ldap/o=puavo`

(1..300).each do |num|
  dir = "/var/lib/ldap/db%03d" % num

  `mkdir -p #{dir}`
  `chown openldap.openldap #{dir}`
  `chmod 0750 #{dir}`
end

`cp schema/*.ldif /etc/ldap/schema/`
`rm -rf /etc/ldap/slapd.d/*`

@servers = ["ldap://ldap1.opinsys.fi",
            "ldap://ldap2.opinsys.fi",
            "ldap://ldap3.opinsys.fi"]

`cp certs/slapd-ca.crt /etc/ssl/certs/slapd-ca.crt`
`cp certs/slapd-server.crt /etc/ssl/certs/slapd-server.crt`
`cp certs/slapd-server.key /etc/ssl/certs/slapd-server.key`

`chown root.openldap /etc/ssl/certs/slapd-server.key`
`chown root.openldap /etc/ssl/certs/slapd-server.crt`
`chown root.openldap /etc/ssl/certs/slapd-ca.crt`

tempfile = parse_erb("init_ldap")
print `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b "cn=config"`
tempfile.delete

tempfile = parse_erb("init_puavo_db")
print `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b "o=Puavo"`
tempfile.delete

`chown -R openldap.openldap /etc/ldap/slapd.d`

#["init_ldap",
# "init_puavo_db"].each do |basename|
#  ldif_template = File.read("templates/#{basename}.ldif.erb")
#  ldif = ERB.new(ldif_template, 0, "%<>")

#  tempfile = Tempfile.open(basename)
#  tempfile.puts ldif.result
#  tempfile.close
#end

#ldif_template = File.read("templates/init_puavo_db.ldif.erb")
#ldif = ERB.new(ldif_template, 0, "%<>")

#tempfile = Tempfile.open("init_ldap")
#tempfile.puts ldif.result
#tempfile.close

#print `slapadd -l #{tempfile.path} -F /etc/ldap/slapd.d -b "o=puavo"`

#tempfile.delete

`chown -R openldap.openldap /var/lib/ldap/o=puavo`
`chmod 0750 /var/lib/ldap/o=puavo`

`/etc/init.d/slapd start`

["set_global_acl",
 "set_syncrepl_settings",
 "set_puavo_syncrepl_settings"].each do |basename|

  ldif_template = File.read("templates/#{basename}.ldif.erb")
  ldif = ERB.new(ldif_template, 0, "%<>")

  tempfile = Tempfile.open(basename)
  tempfile.puts ldif.result
  tempfile.close

  print `cat #{tempfile.path}`
  `ldapmodify -Y EXTERNAL -H ldapi:/// -f #{tempfile.path} 2> /dev/null`

  tempfile.delete

#  `/etc/init.d/slapd restart`
end

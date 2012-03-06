#!/usr/bin/ruby

require 'rubygems'
require "erb"
require 'readline'
require 'ldap'
require 'lib/database_acl'
require 'yaml'

if configuration = YAML.load_file("config/ldap.yml") rescue nil
  @ldaphost = configuration['settings']['ldap_server']['host']
  @binddn = configuration['settings']['ldap_server']['bind_dn']

  puts "Connecting to #{@ldaphost} as #{@binddn}...\n"
else
  puts "ERROR: Could not open LDAP configuration file (config/ldap.yml)"
  exit
end

organisation_name = ARGV.first
puts "******************************************************"
puts "  Initialising organisation: #{organisation_name}"
puts "******************************************************"

puts "#{@binddn} password:"
@bindpw = Readline.readline('> ', true)

def update_acls(suffix)
  dn = ""
  domain = ""
  samba_domain = ""
  kerberos_realm = ""

  conn = LDAP::SSLConn.new(host=@ldaphost, port=636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

  conn.bind(@binddn, @bindpw) do
    begin
      conn.search("cn=config", LDAP::LDAP_SCOPE_SUBTREE, "(olcSuffix=#{suffix})") {|e|
        dn = e.dn
        puts "DN: #{dn}"
      }

      conn.search(suffix, LDAP::LDAP_SCOPE_BASE, "(objectClass=eduOrg)") {|e|
        samba_domain = e.get_values('sambaDomainName')[0]
        kerberos_realm = e.get_values('puavoKerberosRealm')[0]
        domain = e.get_values('puavoDomain')[0]
      }

      rescue LDAP::ResultError
        conn.perror("LDAP connection failed")
        puts "LDAP connection failed"
      end  
  end

  puts
  puts "suffix:         #{suffix}"
  puts "Domain:         #{domain}"
  puts "Kerberos realm: #{kerberos_realm}"
  puts "Samba domain:   #{samba_domain}"

  if samba_domain.eql?("") or kerberos_realm.eql?("") or domain.eql?("")
    puts "ERROR: Couldn't figure out domain information!"
    exit
  end

  Readline.readline('OK?', true)

  File.open('/tmp/acl.ldif', 'w') {|f|
    f.write "dn: #{dn}\n"
    f.write "changetype: modify\n"
    f.write "replace: olcAccess\n"

    f.write LdapAcl.generate_acls(suffix, samba_domain)

### XXX This might trigger some bug in slapd... olcAuthzRegexp does appear to
### XXX work after add, but after delete+add afterwards AND slapd restart
### XXX it no longer does (?!?).  Delete is pointless anyway, and this ends up
### XXX changing the rule order, but of course slapd should not behave that
### XXX way.  The possible slapd bug should be confirmed in some proper test
### XXX environment.
#   f.write "\n\n"
#   f.write "dn: cn=config\n"
#   f.write "changetype: modify\n"
#   f.write "delete: olcAuthzRegexp\n"
#   f.write "olcAuthzRegexp: uid=([^,]*)@#{kerberos_realm.downcase},cn=gssapi,cn=auth ldap:///ou=People,#{suffix}??one?(uid=$1)\n"
#
#   f.write "\n\n"
#   f.write "dn: cn=config\n"
#   f.write "changetype: modify\n"
#   f.write "add: olcAuthzRegexp\n"
#   f.write "olcAuthzRegexp: uid=([^,]*)@#{kerberos_realm.downcase},cn=gssapi,cn=auth ldap:///ou=People,#{suffix}??one?(uid=$1)\n"
  }

  puts `ldapmodify -c -h #{@ldaphost} -x -D #{@binddn} -Z -w #{@bindpw} -f /tmp/acl.ldif`
end

if organisation_name.eql?("--all")
  conn = LDAP::SSLConn.new(host=@ldaphost, port=636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

  conn.bind(@binddn, @bindpw) do
    begin
      puts "Looping through databases"

      conn.search("", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)", ["namingContexts"]) {|e|
        e.get_values("namingContexts").each {|suffix|
          if !suffix.eql?("o=puavo")
            update_acls(suffix)
          end
        }
      }

      rescue LDAP::ResultError
        conn.perror("LDAP connection failed")
        puts "LDAP connection failed"
      end  
  end
else
  # Suffix for single organisation is determined using template

  organisation_base_template = "dc=edu,dc=%s,dc=fi"
  suffix = organisation_base_template % organisation_name

  update_acls(suffix)
end

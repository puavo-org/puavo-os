#!/usr/bin/ruby

require 'rubygems'
require "erb"
require 'readline'
require 'ldap'
require 'database_acl'
require 'yaml'
require 'puavo/etc'


organisation_name = ARGV.first
puts "******************************************************"
puts "  Initialising organisation: #{organisation_name}"
puts "******************************************************"

puts "#{PUAVO_ETC.ldap_dn} password:"
@bindpw = Readline.readline('> ', true)

def update_acls(suffix)
  dn = ""
  domain = ""
  samba_domain = ""
  kerberos_realm = ""

  conn = LDAP::SSLConn.new(host=PUAVO_ETC.ldap_master, port=636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

  conn.bind(PUAVO_ETC.ldap_dn, @bindpw) do
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

    acls = LdapAcl.generate_acls(suffix, samba_domain)
    acls_with_olcAccess = acls.map { |s| s.sub(/^/, 'olcAccess: ') }
    f.write acls_with_olcAccess.join('')

  }

  puts `ldapmodify -c -h #{PUAVO_ETC.ldap_master} -x -D #{PUAVO_ETC.ldap_dn} -Z -w #{@bindpw} -f /tmp/acl.ldif`
end

if organisation_name.eql?("--all")
  conn = LDAP::SSLConn.new(host=PUAVO_ETC.ldap_master, port=636)
  conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

  conn.bind(PUAVO_ETC.ldap_dn, @bindpw) do
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

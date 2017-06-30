#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require "yaml"

require './lib/settings.rb'
require './lib/slapd.rb'

#conf = YAML::load_file( "config/puavo.yml" )

conf = PuavoSetup.configuration

settings = PuavoSetup::ServerSettings.new(:server_uri => conf['server']['server_uri'],
                                          :schemas => conf['server']['schemas'],
                                          :ca_fqdn => conf['server']['ca_fqdn'],
                                          :server_fqdn => conf['server']['server_fqdn'],
                                          :server_port => conf['server']['server_port'],
                                          :cert_organisation => conf['server']['cert_organisation'],
                                          :cert_unit => conf['server']['cert_unit'],
                                          :cert_locality => conf['server']['cert_locality'],
                                          :cert_state => conf['server']['cert_state'],
                                          :cert_country => conf['server']['cert_country'],
                                          :cert_serial => conf['server']['cert_serial'],
                                          :cert_expiration_days => conf['server']['cert_expiration_days'],
                                          :connect_dn => conf['server']['connect_dn'],
                                          :connect_password => conf['server']['connect_password'])

puavodbsettings = PuavoSetup::DatabaseSettings.new(:server => settings,
                                                   :suffix => conf['puavo']['suffix'],
                                                   :domain => conf['puavo']['domain'],
                                                   :rootdn => conf['puavo']['rootdn'],
                                                   :rootpw => conf['puavo']['rootpw'],
                                                   :puavo_user_password => conf['puavo']['puavopw'])


puts "Doing slapd settings:"

slapd = PuavoSetup::SLAPD.new
PuavoSetup::SLAPD.setup_certificates(settings)

result = PuavoSetup::SLAPD.check_schemas(settings.schemas)

if ! result[:missing_schemas].empty?
  puts "Adding missing schemas: #{result[:missing_schemas].join(", ")}"

  result[:missing_schemas].each do |schema|
    PuavoSetup::SLAPD.add_schema(schema)
  end
else
  puts "* Schemas OK"
end

result = PuavoSetup::SLAPD.setup_modules("back_hdb dynlist unique ppolicy syncprov memberof valsort auditlog refint constraint smbkrb5pwd".split)
if !result.empty?
  puts "* Added modules: #{result.join(', ')}"
else
  puts "* Modules OK"
end

puts "Setup global ACL..."
PuavoSetup::SLAPD.setup_global_acl

if !slapd.database_exists?(puavodbsettings)
  PuavoSetup::SLAPD.create_database(puavodbsettings)
end

PuavoSetup::SLAPD.initialize_puavo_suffix(puavodbsettings)
PuavoSetup::SLAPD.setup_puavo_database_acls(puavodbsettings)

puts "******************************************************"
puts "Initialising organisations"
puts "******************************************************"

kadmind_ports = {}

conf['organisations'].each do |org|
  puts "org: #{org['name']}"

  if org['kadmin_port']
    kadmind_ports[org['realm']] = org['kadmin_port']
  end

  kdc_ldappw = org['passwords']['kdc']
  kadmin_ldappw = org['passwords']['kadmin']
  kerberos_masterpw = org['passwords']['kerberos_master']
  sambapw = org['passwords']['samba']

  suffix = org['suffix']

  if !suffix
    domain.split(".").each do |tmp|
      if !suffix.empty?
        suffix.concat(",")
      end

      suffix.concat("dc=#{tmp}")
    end
  end

  dbsettings = PuavoSetup::DatabaseSettings.new(:server => settings,
                                                :suffix => org['suffix'],
                                                :domain => org['domain'],
                                                :kerberos_realm => org['realm'],
                                                :kdc_ldapdn => "uid=kdc,ou=System Accounts,#{suffix}",
                                                :kdc_ldappw => kdc_ldappw,
                                                :kadmin_ldapdn => "uid=kadmin,ou=System Accounts,#{suffix}",
                                                :kadmin_ldappw => kadmin_ldappw,
                                                :kerberos_masterpw => kerberos_masterpw,
                                                :samba_domain => org['samba_domain'],
                                                :samba_rootpw => sambapw,
                                                :org_name => org['name'],
                                                :rootdn => conf['puavo']['rootdn']
                                                )

  old_sid = PuavoSetup::SLAPD.find_samba_sid(dbsettings)

  if old_sid
    puts "Using existing samba SID #{old_sid}"

    dbsettings.samba_sid = old_sid
  end
  
  puts "Kerberos KDC ldap password for realm #{org['realm']}: #{kdc_ldappw}"
  puts "Kerberos kadmin ldap password for realm #{org['realm']}: #{kadmin_ldappw}"
  puts "Kerberos master password for realm #{org['realm']}: #{kerberos_masterpw}"
  puts "Samba domain: #{org['samba_domain']}"
  puts "Samba SID: #{dbsettings.samba_sid}"
  
  #puts settings.inspect
  #puts dbsettings.inspect

  slapd = PuavoSetup::SLAPD.new
  if slapd.database_exists?(dbsettings)
    puts "Database for suffix #{dbsettings.suffix} exists already, not doing anything..."
  else
    puts "Creating database for suffix #{dbsettings.suffix}"
    PuavoSetup::SLAPD.create_database(dbsettings)
  end

  PuavoSetup::SLAPD.configure_db_overlays(dbsettings)
  PuavoSetup::SLAPD.initialize_root(dbsettings)
  PuavoSetup::SLAPD.initialize_ous(dbsettings)
  PuavoSetup::SLAPD.initialize_admin_users(dbsettings)
  PuavoSetup::SLAPD.initialize_autofs(dbsettings)
  PuavoSetup::SLAPD.setup_database_acls(dbsettings)
  PuavoSetup::SLAPD.insert_samba_data(dbsettings)
  #PuavoSetup::SLAPD.setup_sasl(dbsettings)
end

puts "******************************************************"
puts "Setting up kerberos configuration"
puts "******************************************************"

PuavoSetup::SLAPD.setup_kdc_kadmin(settings, conf['server']['default_realm'], kadmind_ports)

puts "******************************************************"
puts "Initialising kerberos realms for organisations"
puts "******************************************************"

conf['organisations'].each do |org|
  puts "org: #{org['name']}"

  domain=org['domain']
  samba_domain=org['samba_domain']
  org_name=org['name']
  samba_sid=nil
  kerberos_realm=org['realm']

  kdc_ldappw = org['passwords']['kdc']
  kadmin_ldappw = org['passwords']['kadmin']
  kerberos_masterpw = org['passwords']['kerberos_master']
  sambapw = org['passwords']['samba']

  suffix = org['suffix']

  if !suffix
    domain.split(".").each do |tmp|
      if !suffix.empty?
        suffix.concat(",")
      end

      suffix.concat("dc=#{tmp}")
    end
  end

  dbsettings = PuavoSetup::DatabaseSettings.new(:server => settings,
                                                :suffix => suffix,
                                                :domain => domain,
                                                :kerberos_realm => kerberos_realm,
                                                :kdc_ldapdn => "uid=kdc,ou=System Accounts,#{suffix}",
                                                :kdc_ldappw => kdc_ldappw,
                                                :kadmin_ldapdn => "uid=kadmin,ou=System Accounts,#{suffix}",
                                                :kadmin_ldappw => kadmin_ldappw,
                                                :kerberos_masterpw => kerberos_masterpw,
                                                :samba_domain => samba_domain,
                                                :samba_rootpw => sambapw,
                                                :samba_sid => samba_sid,
                                                :org_name => "#{org_name}",
                                                :rootdn => conf['puavo']['rootdn']
                                                )

  PuavoSetup::SLAPD.setup_kerberos(dbsettings)
end

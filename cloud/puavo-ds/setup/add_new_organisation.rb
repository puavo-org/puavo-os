#!/usr/bin/ruby
#
# Usage: ruby add_new_organisation.rb <organisation name>
#

$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), 'lib' ) )

require 'rubygems'
require 'active_ldap'
require 'admin_user'
require 'automount'
require 'database'
require 'group'
require 'organisation'
require 'organizational_unit'
require 'samba'
require 'overlay'

LDAP_CONFIG = YAML.load_file("./config/ldap.yml")

ActiveLdap::Base.setup_connection( :host => LDAP_CONFIG["host"],
                                   :base => "cn=config",
                                   :bind_dn => LDAP_CONFIG["bind_dn"],
                                   :password => LDAP_CONFIG["password"] )

organisation_name = ARGV.first
puts "******************************************************"
puts "  Initialising organisation: #{organisation_name}"
puts "******************************************************"


olcSuffix = "dc=edu,dc=#{organisation_name},dc=fi"
olcRootDN = LDAP_CONFIG["bind_dn"]

puts "* Creating database for suffix: #{olcSuffix}"
new_db = Database.new( "olcSuffix" => olcSuffix,
                       "olcRootDN" => olcRootDN )
# Save without validation
new_db.save(false)

new_db = Database.find(:first, :attribute => 'olcSuffix', :value => olcSuffix)

puts "* Setting up overlay configuration to database"
Overlay.create_overlays(new_db)

puts "* Create organisation root"
ActiveLdap::Base.setup_connection( :host => LDAP_CONFIG["host"],
                                   :base => "dc=#{organisation_name},dc=fi",
                                   :bind_dn => LDAP_CONFIG["bind_dn"],
                                   :password => LDAP_CONFIG["password"] )
organisation = Organisation.create( :owner => LDAP_CONFIG["bind_dn"] )

puts "* Add organizational units: People, Groups, Hosts, Automount, etc..."
OrganizationalUnit.create_units(organisation)

puts "* Setting up Autofs configuration"
Automount.create_automount_configuration

puts "* Setting up Samba configuration"
Samba.create_samba_configuration(organisation_name)

puts "* Add admin users: kdc, kadmin, samba"
AdminUser.create_admin_user

#!/usr/bin/ruby
#
# Usage: ruby add_new_organisation.rb <organisation name>
#

$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), 'lib' ) )

require 'rubygems'
require 'active_ldap'
require 'ldap_organisation_base'
require 'admin_user'
require 'automount'
require 'database'
require 'group'
require 'organisation'
require 'organizational_unit'
require 'samba'
require 'overlay'

# FIXME: puavo configuration?
organisation_base_template = "dc=edu,dc=%s,dc=fi"

# LDAP configuration
if configurations = YAML.load_file("config/ldap.yml") rescue nil
  ActiveLdap::Base.configurations = configurations
else
  puts "Not found LDAP configuration file (config/ldap.yml)"
  exit
end

organisation_name = ARGV.first
puts "******************************************************"
puts "  Initialising organisation: #{organisation_name}"
puts "******************************************************"


suffix = organisation_base_template % organisation_name
rootDN = configurations["puavo"]["bind_dn"]

puts "* Creating database for suffix: #{suffix}"

new_db = Database.new( "olcSuffix" => suffix,
                       "olcRootDN" => rootDN )
# Save without validation
new_db.save(false)

new_db = Database.find(:first, :attribute => 'olcSuffix', :value => suffix)

puts "* Setting up overlay configuration to database"
Overlay.create_overlays(new_db)

# Create organisation and set LdapOrganisationBase LDAP connection
puts "* Create organisation root"
organisation = Organisation.create( :owner => configurations["puavo"]["bind_dn"],
                                    :suffix => suffix )

puts "* Add organizational units: People, Groups, Hosts, Automount, etc..."
OrganizationalUnit.create_units(organisation)

puts "* Setting up Autofs configuration"
Automount.create_automount_configuration

puts "* Setting up Samba configuration"
Samba.create_samba_configuration(organisation_name)

puts "* Add admin users: kdc, kadmin, samba"
AdminUser.create_admin_user

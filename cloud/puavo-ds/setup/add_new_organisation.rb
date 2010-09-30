#!/usr/bin/ruby
#
# Usage: ruby add_new_organisation.rb <organisation name>
#

$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), 'lib' ) )

require 'rubygems'
require 'active_ldap'
# LDAP configuration
if configurations = YAML.load_file("config/ldap.yml") rescue nil
  ActiveLdap::Base.configurations = configurations
else
  puts "Not found LDAP configuration file (config/ldap.yml)"
  exit
end

require 'ldap_organisation_base'
require 'admin_user'
require 'automount'
require 'database'
require 'samba_group'
require 'organisation'
require 'organizational_unit'
require 'samba'
require 'overlay'
require 'users/ldap_base'
require 'users/base_group'
require 'users/school'
require 'users/role'
require 'users/group'
require 'users/user_error'
require 'users/user'
require 'users/samba_domain'
require 'users/ldap_organisation'
require 'kerberos'

def newpass( len )
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  newpass = ""
  1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
  return newpass
end


# FIXME: puavo configuration?
organisation_base_template = "dc=edu,dc=%s,dc=fi"

organisation_name = ARGV.first
puts "******************************************************"
puts "  Initialising organisation: #{organisation_name}"
puts "******************************************************"

domain = "#{organisation_name}.opinsys.fi"
kerberos_realm = domain.upcase
legal_name = organisation_name
puppet_host = "#{organisation_name}.puppet.opinsys.fi"

suffix = organisation_base_template % organisation_name
rootDN = configurations["settings"]["ldap_server"]["bind_dn"]

puts "* Creating database for suffix: #{suffix}"
begin
  new_db = Database.new( "olcSuffix" => suffix,
                       "olcRootDN" => rootDN )
  # Save without validation
  new_db.save(false)
rescue => e
  puts e
  exit
end

new_db = Database.find(:first, :attribute => 'olcSuffix', :value => suffix)

puts "* Setting up overlay configuration to database"
Overlay.create_overlays(:database => new_db,
                        :kerberos_realm => kerberos_realm)

if ActiveLdap::Base.configurations["settings"]["syncrepl"]["nodes"]
  puts "* Setting up replication configuration"
  new_db.set_replication_settings
end

# Create organisation and set LdapOrganisationBase LDAP connection
puts "* Create organisation root"
organisation = Organisation.create( :owner => configurations["settings"]["ldap_server"]["bind_dn"],
                                    :suffix => suffix,
                                    :puavoDomain => domain,
                                    :puavoKerberosRealm => kerberos_realm,
                                    :o => organisation_name,
                                    :cn => organisation_name,
                                    :description => organisation_name,
                                    :eduOrgLegalName => legal_name,
                                    :puavoPuppetHost => puppet_host )

puts "* Add organizational units: People, Groups, Hosts, Automount, etc..."
OrganizationalUnit.create_units(organisation)

puts "* Setting up Autofs configuration"
Automount.create_automount_configuration

puts "* Setting up Samba configuration"
Samba.create_samba_configuration(organisation_name)

puts "* Add admin users: kdc, kadmin, samba"
AdminUser.create_admin_user

# School
school = School.first
puts "\nCreate new school"
school_name = "Administration"
puts "School name: #{school_name}" 
school = School.create!( :displayName => school_name,
                         :cn => school_name.downcase.gsub(/[^a-z0-9]/, "") )

# Role
puts "Create new role"
role_name = "Maintenance"
puts "Role name: #{role_name}"
role = Role.create!( :displayName => role_name,
                    :puavoSchool => school.dn )

# Group
puts "Create new group"
group_name = "Maintenance"
puts "Group name: #{group_name}"
group = Group.create!( :displayName => group_name,
                      :cn => group_name.downcase.gsub(/[^a-z0-9]/, ""),
                      :puavoSchool => school.dn )

# Added association
role.groups << group

# Create kerberos realm

#`mkdir -p /etc/krb5kdc/masterkeys`
#`chmod 0700 /etc/krb5kdc/masterkeys`

kerberos_masterpw = newpass(20)
puts "Initializing kerberos realm with master key: #{kerberos_masterpw}"

realm = KerberosRealm.new( :ldap_server => configurations["settings"]["ldap_server"],
                           :realm => kerberos_realm,
                           :masterpw => kerberos_masterpw,
                           :suffix => suffix,
                           :domain => domain )

conf = KerberosRealm.create_kerberos_configuration(configurations["settings"]["ldap_server"])

File.open("/etc/krb5kdc/kdc.conf", "w") {|file|
        file.write(conf.kdc_conf)
}

File.open("/etc/krb5.conf", "w") {|file|
        file.write(conf.krb5_conf)
}

File.open("/etc/krb5kdc/kadm5.acl", "w") {|file|
        file.write(conf.kadm5_acl)
}

File.open("/etc/default/krb5-kdc", "w") {|file|
        file.write(conf.daemon_args)
}

realm.create_ldap_tree

puts configurations["settings"]["puppet"]["enable"]

if configurations["settings"]["puppet"]["enable"]
  `cp /etc/krb5kdc/* #{configurations["settings"]["puppet"]["file_dir"]}/etc/krb5kdc/`
  `cp /etc/krb5.conf #{configurations["settings"]["puppet"]["file_dir"]}/etc/`
  `cp /etc/default/krb5-kdc #{configurations["settings"]["puppet"]["file_dir"]}/etc/default/krb5-kdc`
  `chown -R puppet #{configurations["settings"]["puppet"]["file_dir"]}/*`

  puts "Puppet kerberos files updated"
else
  puts "Puppet configuration disabled"
end

# User
puts "Create organisation owner:"

print "Given name: "
given_name = STDIN.gets.chomp

print "Surname: "
surname = STDIN.gets.chomp
print "Username: "
username = STDIN.gets.chomp
system('stty','-echo');
print "Password: "
password = STDIN.gets.chomp
print "\nPassword confirmation: "
password_confirmation = STDIN.gets.chomp
system('stty','echo');

user = User.new

user.givenName = given_name
user.sn = surname
user.uid = username
user.new_password = password
user.new_password_confirmation = password_confirmation
user.role_name = role.displayName
user.puavoSchool = school.dn
user.puavoEduPersonAffiliation = "admin"
user.save!

puts
puts "User was successfully created."
puts "\nSets the user (#{user.uid}) as the owner of the organisation"
ldap_organisation = LdapOrganisation.first
ldap_organisation.owner = Array(ldap_organisation.owner).push user.dn
ldap_organisation.save

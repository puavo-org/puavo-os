require 'active_ldap'
require 'optparse'
require 'readline'

# LDAP configuration
if CONFIGURATIONS = YAML.load_file("/etc/puavo-ldap.yml") rescue nil
  ActiveLdap::Base.configurations = CONFIGURATIONS
else
  puts "Not found LDAP configuration file (/etc/puavo-ldap.yml)"
  exit
end

require 'puavo-ds/ldap_organisation_base'
require 'puavo-ds/admin_user'
require 'puavo-ds/database'
require 'puavo-ds/samba_group'
require 'puavo-ds/samba_sid_group'
require 'puavo-ds/organisation'
require 'puavo-ds/organizational_unit'
require 'puavo-ds/samba'
require 'puavo-ds/overlay'
require 'puavo-ds/system_group'
require 'puavo-ds/users/ldap_base'
require 'puavo-ds/users/base_group'
require 'puavo-ds/users/school'
require 'puavo-ds/users/role'
require 'puavo-ds/users/group'
require 'puavo-ds/users/user_error'
require 'puavo-ds/users/user'
require 'puavo-ds/users/samba_domain'
require 'puavo-ds/users/ldap_organisation'
require 'puavo-ds/kerberos'
require 'puavo-ds/id_pool'
require 'puavo-ds/database_acl'
require 'puavo-ds/overlay/syncprov'
require 'puavo-ds/overlay/unique'
require 'puavo-ds/overlay/memberof'
require 'puavo-ds/overlay/smbkrb5pwd'
require 'puavo-ds/overlay/constraint'
#require 'puavo-ds/oauth'
#require 'puavo-ds/oauth_client'
#require 'puavo-ds/oauth_token'

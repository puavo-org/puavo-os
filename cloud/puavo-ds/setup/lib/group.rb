class Group < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "cn",
                :prefix => "ou=Groups,dc=edu",
                :classes => ["top","posixGroup", "sambaGroupMapping"] )
end

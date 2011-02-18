class SambaGroup < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "cn",
                :prefix => "ou=Groups",
                :classes => ["top","posixGroup", "sambaGroupMapping"] )
end

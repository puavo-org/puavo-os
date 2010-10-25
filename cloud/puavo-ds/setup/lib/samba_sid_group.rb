class SambaSidGroup < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "sambaSID",
                :prefix => "ou=Groups,dc=edu",
                :classes => ["sambaSidEntry", "sambaGroupMapping"] )
end

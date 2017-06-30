class SambaSidGroup < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "sambaSID",
                :prefix => "ou=Groups",
                :classes => ["sambaSidEntry", "sambaGroupMapping"] )
end

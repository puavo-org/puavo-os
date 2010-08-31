class LdapOrganisation < LdapBase
  ldap_mapping( :dn_attribute => "dc",
                :prefix => "",
                :classes => ["dcObject", "organization", "puavoEduOrg", "eduOrg"] )
end

class OAuthToken < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "ou",
                :prefix => "ou=OAuth",
                :classes => ["top","organizationalUnit"] )

end

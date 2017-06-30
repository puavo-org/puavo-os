class SambaDomain < LdapBase
  ldap_mapping( :dn_attribute => "sambaDomainName",
                :prefix => "",
                :classes => ['top', 'sambaDomain'] )

end

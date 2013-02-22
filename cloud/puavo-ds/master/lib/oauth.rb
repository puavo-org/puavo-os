class OAuth < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "ou",
                :prefix => "",
                :classes => ['top', 'organizationalUnit'] )

  def self.create_oauth_branch

    self.create( "ou" => "OAuth" )
    OAuthClient.create( "ou" => "Clients" )
    OAuthToken.create( "ou" => "Tokens" )
  end
    
end

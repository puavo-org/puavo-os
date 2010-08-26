class Automount < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "ou",
                :prefix => "ou=Automount" )

  def self.create_automount_configuration
    self.create( "ou" => "auto.master",
                 "objectClass" => ['top', 'automountMap'])
    
    self.create( "ou" => "auto.direct",
                 "objectClass" => ['top', 'automountMap'])

    self.ldap_mapping( :dn_attribute => "cn",
                       :prefix => "ou=auto.master,ou=Automount" )
    
    # Save without validation
    self.new( "cn" => "/-",
              "objectClass" => 'automount',
              "automountInformation" => "ldap:ou=auto.direct,ou=Automount,#{self.base}" ).save(false)
  end
end

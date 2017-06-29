class AdminUser < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "uid",
                :prefix => "ou=System Accounts",
                :classes => ['account', 'simpleSecurityObject'] )

  def self.create_admin_user
    # FIXME: generate passwords
    kdc_ldappw_hash = "FIXME"
    kadmin_ldappw_hash = "FIXME"
    samba_rootpw_hash = "FIXME"
    
    self.create( 'uid' => "kdc",
                 'description' => "Kerberos root",
                 'userPassword' => kdc_ldappw_hash )

    self.create( 'uid' => "kadmin",
                 'description' => "Kerberos root",
                 'userPassword' => kadmin_ldappw_hash )

    self.create( 'uid' => "samba",
                 'description' => "Samba root",
                 'userPassword' => samba_rootpw_hash )
  end
end

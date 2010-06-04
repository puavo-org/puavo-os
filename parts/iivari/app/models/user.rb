class User < OrganisationData
  acts_as_authentic do |c| 
    c.validate_password_field false 
  end 

  def ldap_entry
    LdapUser.find(self.login)
  end
  
  def self.find_or_create_from_ldap(login)
    find_by_login(login) || create_from_ldap_if_valid(login)
  end
  
  def self.create_from_ldap_if_valid(login)
    User.create(:login => login) if LdapUser.find(login)
  end
  
  protected

  def valid_ldap_credentials?(password_plaintext)
    if ldap_entry.bind(password_plaintext)
      return true
    end
    return false
  end
end

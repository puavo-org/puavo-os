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
    begin
      User.create(:login => login) if LdapUser.find(login)
    rescue Exception => e
      logger.info "Execption: " + e
      nil
    end
  end

  protected

  def valid_ldap_credentials?(password_plaintext)
    begin 
      if ldap_entry.bind(password_plaintext)
        true
      end
    rescue Exception => e
      logger.info "Authentication error: " + e.to_s
      false
    end
  end
end

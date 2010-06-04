class LdapUser

  attr_accessor :dn, :ldap

  def self.find(uid)
    ldap = Net::LDAP.new
    ldap.host = Organisation.current.ldap_host
    ldap.auth(Organisation.current.uid_search_dn, Organisation.current.uid_search_password)

    if ldap.bind
      filter = Net::LDAP::Filter.eq( "uid", uid )
      treebase = Organisation.current.ldap_base
      
      ldap_user = LdapUser.new
      ldap.search( :base => treebase, :filter => filter ) do |entry|
        ldap_user.dn = entry.dn
        ldap_user.ldap = ldap
        return ldap_user
      end
      return false
    end
  end

  def bind(password)
    self.ldap.auth(self.dn, password)
    self.ldap.bind
  end
end

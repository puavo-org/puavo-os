class LdapUser

  attr_accessor :dn, :ldap

  def self.find(uid)
    ldap = LDAP::Conn.new( Organisation.current.ldap_host )
    ldap.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    ldap.start_tls

    if ldap.bound? || ldap.bind(Organisation.current.uid_search_dn, Organisation.current.uid_search_password)
      filter = "(uid=#{uid})"
      treebase = Organisation.current.ldap_base
      
      ldap_user = LdapUser.new
      ldap.search(treebase, LDAP::LDAP_SCOPE_SUBTREE, filter) do |entry|
        ldap_user.dn = entry.dn
        ldap_user.ldap = ldap
        return ldap_user
      end
      return false
    end
  end

  def bind(password)
    ldap = LDAP::Conn.new( Organisation.current.ldap_host )
    ldap.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    ldap.start_tls

    ldap.bind(self.dn, password)
  end
end

class LdapUser

  attr_accessor :dn, :ldap, :puavo_id

  def self.find(uid)
    host = Organisation.current.ldap_host
    ldap = LDAP::Conn.new( host )
    ldap.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    ldap.start_tls if Organisation.current.value_by_key('ldap_method') == 'tls'

    if ldap.bound? || ldap.bind(Organisation.current.uid_search_dn, Organisation.current.uid_search_password)
      logger.debug("LDAP bind to %s" % host)
      filter = "(uid=#{uid})"
      treebase = Organisation.current.ldap_base
      
      ldap_user = LdapUser.new
      logger.debug "Searching tree at base %s with filter %s and SCOPE_SUBTREE" % [treebase, filter]
      ldap.search(treebase, LDAP::LDAP_SCOPE_SUBTREE, filter) do |entry|
        ldap_user.puavo_id = entry["puavoId"].first.to_i
        ldap_user.dn = entry.dn
        ldap_user.ldap = ldap
        logger.debug "Found user: " % ldap_user.inspect
        return ldap_user
      end
      return false
    end
  end
  
  def self.logger
    Rails.logger
  end

  def bind(password)
    ldap = LDAP::Conn.new( Organisation.current.ldap_host )
    ldap.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    ldap.start_tls if Organisation.current.value_by_key('ldap_method') == 'tls'

    ldap.bind(self.dn, password)
  end
end

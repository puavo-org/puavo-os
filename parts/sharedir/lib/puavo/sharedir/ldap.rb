require 'ldap'
require 'socket'

class PuavoLdap
  attr_reader :base, :dn, :password

  Puavodomain        = File.read('/etc/puavo/domain').chomp
  Default_ldapserver = "#{ Socket.gethostname }.#{ Puavodomain }"

  def initialize(ldapserver='localhost')
    @base     = File.read('/etc/puavo/ldap/base'    ).chomp
    @dn       = File.read('/etc/puavo/ldap/dn'      ).chomp
    @password = File.read('/etc/puavo/ldap/password').chomp

    if ldapserver == 'localhost' then
      ldapserver = Default_ldapserver
    end

    if ldapserver
      @conn = LDAP::Conn.new(ldapserver)
      @conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      @conn.start_tls
      @conn.bind(@dn, @password)

      @my_fqdn = "#{ Socket.gethostname }.#{ Puavodomain }"
    else
      @conn = nil
    end
  end

  def search(filter, &block)
    search_with_base(@base, filter, &block)
  end

  def search_with_base(base, filter, &block)
    return [] unless @conn
    @conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, filter, &block)
  end

  def search_with_baseprefix(baseprefix, filter, &block)
    search_with_base("#{ baseprefix },#{ @base }", filter, &block)
  end

  def unbind
    @conn.unbind unless @conn
  end
end

class LdapBase < ActiveLdap::Base
  def self.ldap_setup_connection(host, base, dn, password)
    setup_connection( ensure_configuration.merge( { "host" => host,
                                                    "base" => base,
                                                    "bind_dn" => dn,
                                                    "password" => password } ) )
  end
end

require 'test_helper'

class LdapUserTest < ActiveSupport::TestCase

  # Test LDAP connection and Organisation settings.
  #
  # Tests that the bind user is found from the LDAP tree base.
  test "binddn" do
    organisation = Organisation.find_by_host '*'
    host = organisation.ldap_host

    ldap = LDAP::Conn.new( host )
    ldap.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    ldap.start_tls if organisation.value_by_key('ldap_method') == 'tls'

    binddn = organisation.uid_search_dn
    bindpw = organisation.uid_search_password
    self.assert ldap.bind(binddn, bindpw)

    treebase = organisation.ldap_base
    filter = "(%s)" % binddn.split(','+treebase) # remove treebase from binddn name

    ldap_user = LdapUser.new
    found = false
    ldap.search(treebase, LDAP::LDAP_SCOPE_SUBTREE, filter) do |entry|
      found = true
      ldap_user.dn = entry.dn
    end
    self.assert found, 'could not find binduser %s from tree' % binddn
    self.assert_equal binddn, ldap_user.dn
  end
end

require 'puavo-ds/id_pool'
require 'puavo-ds/database_acl'
require 'puavo-ds/database_config'
require 'tempfile'

class Database < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "olcDatabase",
                :prefix => "",
                :classes => ['olcDatabaseConfig', 'olcMdbConfig'] )

  attr_accessor :kerberos_realm, :samba_domain

  def initialize(args)
    ActiveLdap::Base.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => "cn=config" ) )
    super

    set_attribute_values
  end

  def set_attribute_values
    self.olcDatabase    = 'mdb'
    self.olcDbDirectory = "/var/lib/ldap/#{ self.olcSuffix }"
    self.olcDbIndex     = PUAVO_DB_CONFIG['olcDbIndex']
    self.olcDbMaxSize   = PUAVO_DB_CONFIG['olcDbMaxSize']
    self.olcLastMod     = PUAVO_DB_CONFIG['olcLastMod']

    # Database ACLs
    suffix = self.olcSuffix
    kerberos_realm = self.kerberos_realm
    samba_domain = self.samba_domain

    self.olcAccess = LdapAcl.generate_acls(suffix, kerberos_realm, samba_domain)
  end
end

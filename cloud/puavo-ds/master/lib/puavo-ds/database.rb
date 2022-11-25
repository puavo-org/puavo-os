require 'puavo-ds/id_pool'
require 'puavo-ds/database_acl'
require 'tempfile'

class Database < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "olcDatabase",
                :prefix => "",
                :classes => ['olcDatabaseConfig', 'olcMdbConfig'] )

  attr_accessor :samba_domain
  attr_accessor :kerberos_realm

  PUAVO_DB_CONFIG = {
    'olcDbIndex' => [ 'cn eq,sub',
                      'creatorsName eq',
                      'displayName sub',
                      'entryCSN eq',
                      'gidNumber eq',
                      'givenName sub',
                      'homeDirectory eq',
                      'krbPrincipalName eq',
                      'member eq',
                      'memberUid eq',
                      'objectClass eq',
                      'puavoAdminOfSchool eq',
                      'puavoDevicePrimaryUser eq',
                      'puavoDeviceType eq',
                      'puavoEduGroupType eq',
                      'puavoEduPersonAffiliation eq',
                      'puavoExternalId eq',
                      'puavoHostname eq',
                      'puavoId eq',
                      'puavoPrinterQueue eq',
                      'puavoSchoolAdmin eq',
                      'puavoSchool eq',
                      'puavoServiceDomain eq',
                      'puavoWirelessPrinterQueue eq',
                      'sn sub',
                      'uid eq,sub' ],
    'olcDbMaxSize' => [ '40000000000' ],
    'olcLastMod'   => [ 'TRUE' ],
  }

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

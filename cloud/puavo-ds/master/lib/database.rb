require 'id_pool'
require 'database_acl'
require 'tempfile'

class Database < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "olcDatabase",
                :prefix => "",
                :classes => ['olcDatabaseConfig', 'olcHdbConfig'] )

  attr_accessor :samba_domain
  attr_accessor :kerberos_realm
  before_save :set_attribute_values

  def initialize(args)
    ActiveLdap::Base.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => "cn=config" ) )
    super
  end

  def set_attribute_values
    self.olcDatabase = 'hdb'
    self.olcDbConfig = ['set_cachesize 0 10485760 0',
                        'set_lg_bsize 2097512',
                        'set_flags DB_LOG_AUTOREMOVE']
    self.olcDbCheckpoint = '64 5'
    self.olcDbCachesize = '10000'
    self.olcLastMod = 'TRUE'
    self.olcDbCheckpoint = '512 30'
    self.olcDbIndex = ['sambaSID pres,eq',
                       'sambaSIDList pres,eq',
                       'sambaGroupType pres,eq',
                       'member,memberUid pres,eq',
                       'puavoSchool pres,eq',
                       'puavoId pres,eq',
                       'puavoTag pres,eq',
                       'puavoDeviceType pres,eq',
                       'puavoHostname pres,eq,sub',
                       'displayName,puavoEduPersonReverseDisplayName pres,eq,sub',
                       'uid pres,eq',
                       'krbPrincipalName pres,eq',
                       'cn,sn,mail,givenName pres,eq,approx,sub',
                       'objectClass eq',
                       'entryUUID eq',
                       'entryCSN eq'
                       ]
    self.olcDbDirectory = "/var/lib/ldap/db#{next_directory_id}"

    # Database ACLs
    suffix = self.olcSuffix
    samba_domain = self.samba_domain

    self.olcAccess = LdapAcl.generate_acls(suffix, samba_domain)
  end

  def set_replication_settings
    @rootdn = ActiveLdap::Base.configurations["settings"]["ldap_server"]["bind_dn"]
    @rootpw = ActiveLdap::Base.configurations["settings"]["ldap_server"]["password"]
    @servers = Array.new
    @servers += ActiveLdap::Base.configurations["settings"]["syncrepl"]["urls"] if ActiveLdap::Base.configurations["settings"]["syncrepl"]["hosts"]
    @suffix = self.olcSuffix
    @database_dn = self.dn.to_s

    ldif_template = File.read("templates/set_db_syncrepl_settings.ldif.erb")
    ldif = ERB.new(ldif_template, 0, "%<>")
    
    tempfile = Tempfile.open("set_db_syncrepl_settings")
    tempfile.puts ldif.result(binding)
    tempfile.close

    print `ldapmodify -x -D #{ @rootdn } -w #{@rootpw} -ZZ -H ldap://#{ @servers.first } -f #{tempfile.path}`
    tempfile.delete
  end

  def next_directory_id
    "%03d" % IdPool.next_id('puavoNextDatabaseId')
  end
end

require 'id_pool'
require 'tempfile'

class Database < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "olcDatabase",
                :prefix => "",
                :classes => ['olcDatabaseConfig', 'olcHdbConfig'] )

  before_save :set_attribute_values

  def initialize(args)
    ActiveLdap::Base.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => "cn=config" ) )
    super
  end

  def set_attribute_values
    self.olcDatabase = 'hdb'
    self.olcDbConfig = ['set_cachesize 0 20971520 0',
                        'set_lk_max_objects 1500',
                        'set_lk_max_locks 1500',
                        'set_lk_max_lockers 1500',
                        'set_lk_detect DB_LOCK_OLDEST',
                        'set_log_config DB_LOG_AUTO_REMOVE',
                        'set_lg_max 5242880',
                        'set_lg_bsize 2097512',
                        'set_tx_max 100']
    self.olcDbCheckpoint = '64 5'
    self.olcDbCachesize = '10000'
    self.olcLastMod = 'TRUE'
    self.olcDbCheckpoint = '512 30'
    self.olcDbIndex = ['uid pres,eq',
                       'cn,sn,mail pres,eq,approx,sub',
                       'objectClass eq',
                       'entryUUID eq',
                       'entryCSN eq'
                       ]
    self.olcDbDirectory = "/var/lib/ldap/db#{next_directory_id}"

    # Database ACLs
    suffix = self.olcSuffix
    template = File.read("templates/database_acl.erb")
    self.olcAccess = ERB.new(template, 0, "%<>").result(binding).split("\n")
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
    id_pool = IdPool.find('IdPool')
    next_id = id_pool.puavoNextDatabaseId
    id_pool.puavoNextDatabaseId = next_id + 1
    id_pool.save
    return "%03d" % next_id
  end
end

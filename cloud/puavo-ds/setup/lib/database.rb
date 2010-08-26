class Database < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "olcDatabase",
                :prefix => "",
                :classes => ['olcDatabaseConfig', 'olcHdbConfig'] )

  before_save :set_attribute_values

  private

  def initialize(args)
    ActiveLdap::Base.setup_connection( configurations["puavo"].merge( "base" => "cn=config" ) )
    super
  end

  def set_attribute_values
    self.olcDatabase = 'hdb'
    self.olcDbConfig = ['set_cachesize 0 2097152 0',
                        'set_lk_max_objects 1500',
                        'set_lk_max_locks 1500',
                        'set_lk_max_lockers 1500' ]
    self.olcLastMod = 'TRUE'
    self.olcDbCheckpoint = '512 30'
    self.olcDbIndex = ['uid pres,eq',
                       'cn,sn,mail pres,eq,approx,sub',
                       'objectClass eq' ]
    self.olcDbDirectory = "/var/lib/ldap/db#{next_directory_id}"

    # Database ACLs
    suffix = self.olcSuffix
    template = File.read("templates/database_acl.erb")
    self.olcAccess = ERB.new(template, 0, "%<>").result(binding).split("\n")
  end

  def next_directory_id
    # FIXME, using IdPool (o=Puavo)
    last_database = Database.all.sort do |a,b|
      a.olcDatabase.match(/\{([0-9]+)\}/)[1].to_i <=> b.olcDatabase.match(/\{([0-9]+)\}/)[1].to_i
    end.last
    new_id = (last_database.olcDbDirectory.match(/[0-9]+$/)[0].to_i + 1).to_s
    "0" * (3 - new_id.length) + new_id
  end
end

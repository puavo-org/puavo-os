class Organisation < ActiveLdap::Base  
  ldap_mapping( :dn_attribute => "dc",
                :prefix => "",
                :classes => ['dcObject', 'organization', 'puavoEduOrg', 'eduOrg'] )

  attr_accessor :suffix, :domain, :realm, :name, :legal_name, :puppet_host

  before_validation :set_values
  after_create :set_base_connection

  def initialize(args)
    # Create new LDAP connection with organisation's base: dc=example,dc=org
    base = args[:suffix].match(/,(.+)$/)[1]
    ActiveLdap::Base.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => base ) )
    super
  end

  def set_values
    /(.*?)=(.*?)[$,]/.match(self.suffix.to_s)
#    tmp_dc = self.suffix.to_s.match(/dc=([^,]+),/)[0]
    self.send("#{$1}=", $2)
#    self.dc = $1
#    self.cn = self.name
#    self.puavoDomain = self.domain
#    self.puavoKerberosRealm = self.kerberos_realm
#    self.o = self.name
#    self.description = self.name
#    self.eduOrgLegalName = self.legal_name
    self.puavoKadminPort = IdPool.next_id('puavoNextKadminPort')
  end

  def set_base_connection
    LdapOrganisationBase.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => self.suffix ) )
    LdapBase.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => self.suffix ) )
  end
end

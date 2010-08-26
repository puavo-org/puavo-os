class Organisation < ActiveLdap::Base  
  ldap_mapping( :dn_attribute => "dc",
                :prefix => "",
                :classes => ['dcObject', 'organization', 'puavoEduOrg', 'eduOrg'] )

  attr_accessor :suffix

  before_validation :set_values
  after_create :set_base_connection

  def initialize(args)
    # Create new LDAP connection with organisation's base: dc=example,dc=org
    base = args[:suffix].match(/,(.+)$/)[1]
    ActiveLdap::Base.setup_connection( configurations["puavo"].merge( "base" => base ) )
    super
  end

  def set_values
    organisation_name = self.base.to_s.match(/dc=([^,]+),/)[1]
    self.dc = "edu"
    self.cn = organisation_name.capitalize
    self.puavoDomain = "#{organisation_name}.opinsys.fi"
    self.puavoKerberosRealm = self.puavoDomain.upcase
    self.o = self.puavoDomain
    self.description = self.cn
    self.eduOrgLegalName = self.cn
  end

  def set_base_connection
    LdapOrganisationBase.setup_connection( configurations["puavo"].merge( "base" => self.suffix ) )
  end
end

class Organisation < ActiveLdap::Base  
  ldap_mapping( :dn_attribute => "dc",
                :prefix => "",
                :classes => ['dcObject', 'organization', 'puavoEduOrg', 'eduOrg'] )

  attr_accessor :organisation_name

  before_validation :set_values

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
end

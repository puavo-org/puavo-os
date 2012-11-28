class Organisation < ActiveLdap::Base  
  ldap_mapping( :dn_attribute => "dc",
                :prefix => "",
                :classes => ['dcObject', 'organization', 'puavoEduOrg', 'eduOrg'] )

  attr_accessor :suffix, :domain, :realm, :name, :legal_name, :puppet_host

  before_validation :set_values
  after_create :set_base_connection, :create_remote_desktop_public_key

  def initialize(args)
    # Create new LDAP connection with organisation's base: dc=example,dc=org
    base = args[:suffix].match(/,(.+)$/)[1]
    ActiveLdap::Base.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => base ) )
    super
  end

  private

  def set_values
    /(.*?)=(.*?)[$,]/.match(self.suffix.to_s)
    self.send("#{$1}=", $2)
    self.puavoKadminPort = IdPool.next_id('puavoNextKadminPort')
  end

  def set_base_connection
    LdapOrganisationBase.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => self.suffix ) )
    LdapBase.setup_connection( configurations["settings"]["ldap_server"].merge( "base" => self.suffix ) )
  end

  def create_remote_desktop_public_key
    `/usr/bin/ssh-keygen -q -t dsa -N '' -f /tmp/#{self.cn}`
    self.puavoRemoteDesktopPrivateKey = File.open("/tmp/#{self.cn}").readlines.to_s
    self.puavoRemoteDesktopPublicKey = File.open("/tmp/#{self.cn}.pub").readlines.to_s
    self.save
    File.delete("/tmp/#{self.cn}")
    File.delete("/tmp/#{self.cn}.pub")
  end
end

class OrganizationalUnit < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "ou",
                :prefix => "",
                :classes => ['top', 'organizationalUnit'] )

  def self.create_units(organisation)
    ['People',
     'Groups',
     'Hosts',
     'Automount',
     'Roles',
     'Services',
     'System Accounts',
     'System Groups',
     'Password Policies',
     'Idmap',
     'Kerberos Realms',
     'Desktops'].each do |ou|
      OrganizationalUnit.create( "ou" => ou )
    end
      
    self.ldap_mapping( :dn_attribute => "ou",
                       :prefix => "ou=Hosts",
                       :classes => ['top', 'organizationalUnit'] )
    ['Servers',
     'Devices',
     'Samba'].each do |ou|
      OrganizationalUnit.create( "ou" => ou )

    self.ldap_mapping( :dn_attribute => "ou",
                       :prefix => "ou=Desktops",
                       :classes => ['top', 'organizationalUnit'] )

    ['Applications',
     'Bookmarks',
     'Services'].each do |ou|
      OrganizationalUnit.create( "ou" => ou )
    end
  end
end

class Samba < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "sambaDomainName",
                :prefix => "",
                :classes => ['top', 'sambaDomain'] )

  def self.create_samba_configuration(organisation_name, samba_domain, suffix_start)
    sid1 = rand(100000000)
    sid2 = rand(100000000)
    sid3 = rand(100000000)
    
    samba_sid = "S-1-5-21-#{sid1}-#{sid2}-#{sid3}"

    self.create( "sambaDomainName" =>  samba_domain,
                 'sambaSID' => samba_sid,
                 'sambaAlgorithmicRidBase' => "1000",
                 'sambaNextRid' => "1000",
                 'sambaMinPwdLength' => "7",
                 'sambaPwdHistoryLength' => "0",
                 'sambaLogonToChgPwd' => "0",
                 'sambaMaxPwdAge' => "-1",
                 'sambaMinPwdAge' => "0",
                 'sambaLockoutDuration' => "30",
                 'sambaLockoutObservationWindow' => "30",
                 'sambaLockoutThreshold' => "0",
                 'sambaForceLogoff' => "-1",
                 'sambaRefuseMachinePwdChange' => "0" )

    [
     [512, 'Domain Admins', 'Netbios Domain Administrators'],
     [513, 'Domain Users', 'Netbios Domain Users'],
     [514, 'Domain Guests', 'Netbios Domain Guest Users'],
     [550, 'Print Operators', 'Netbios Domain Print Operators'],
     [551, 'Backup Operators', 'Netbios Domain Members can bypass file security to back up files'],
     [552, 'Replicators', 'Netbios Domain Supports file replication in a sambaDomainName'],
     [553, 'Domain Computers', 'Netbios Domain Computers accounts'],
     [533, 'Administrators', 'Netbios Domain Members can fully administer the computer/sambaDomainName'],
     [545, 'Users', 'Netbios Domain Ordinary users'],
     [546, 'Guests', 'Netbios Domain Users granted guest access to the computer/sambaDomainName'],
     [547, 'Power Users', 'Netbios Domain Members can share directories and printers'],
     [548, 'Account Operators', 'Netbios Domain Users to manipulate users accounts'],
     [549, 'Server Operators', 'Netbios Domain Server Operators']
    ].each do |group_id, group_name, group_description|
      SambaGroup::ldap_mapping( :dn_attribute => "cn",
                                :prefix => "ou=Groups,#{suffix_start}",
                                :classes => ["top","posixGroup", "sambaGroupMapping"] )

      SambaGroup.create( 'sambaSID' => samba_sid + "-" + group_id.to_s,
                         'sambaGroupType' => "2",
                         'displayName' => group_name,
                         'description' => group_description,
                         'gidNumber' => group_id,
                         'cn' => group_name )
    end

    [
     [544, 'Administrators', 512],
     [545, 'Users', 513]
    ].each do |group_id, group_name, sid_list_group|
      SambaSidGroup::ldap_mapping( :dn_attribute => "cn",
                                :prefix => "ou=Groups,#{suffix_start}",
                                :classes => ["top","posixGroup", "sambaGroupMapping"] )

      SambaSidGroup.create( 'sambaSID' => "S-1-5-32-" + group_id.to_s,
                            'sambaGroupType' => "4",
                            'displayName' => group_name,
                            'gidNumber' => group_id,
                            'sambaSIDList' => "#{samba_sid}-#{sid_list_group}" )
    end
  end
end

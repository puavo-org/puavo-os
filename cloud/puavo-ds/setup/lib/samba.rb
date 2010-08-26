class Samba < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "sambaDomainName",
                :prefix => "",
                :classes => ['top', 'sambaDomain'] )

  def self.create_samba_configuration(organisation_name)
    sid1 = rand(100000000)
    sid2 = rand(100000000)
    sid3 = rand(100000000)
    
    samba_sid = "S-1-5-21-#{sid1}-#{sid2}-#{sid3}"

    self.create( "sambaDomainName" =>  "EDU" + organisation_name.upcase,
                 'sambaSID' => samba_sid,
                 'sambaAlgorithmicRidBase' => "1000",
                 'sambaNextUserRid' => "1000",
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
      Group.create( 'sambaSID' => samba_sid + "-" + group_id.to_s,
                    'sambaGroupType' => "2",
                    'displayName' => group_name,
                    'description' => group_description,
                    'gidNumber' => group_id,
                    'cn' => group_name )
    end
  end
end

class SystemGroup < LdapOrganisationBase
  ldap_mapping( :dn_attribute => "cn",
                :prefix => "ou=System Groups",
                :classes => ['puavoSystemGroup'])

  def self.create_system_groups
    group_specs = [
      { 'cn' => 'addressbook',   'description' => 'Addressbook'              },
      { 'cn' => 'auth',          'description' => 'LDAP bind (dn, uid)'      },
      { 'cn' => 'bookmarks',     'description' => 'Bookmarks'                },
      { 'cn' => 'devices',       'description' => 'Client devices'           },
      { 'cn' => 'getent',        'description' => 'getent passwd and group'  },
      { 'cn' => 'nextcloud',     'description' => 'Nextcloud'                },
      { 'cn' => 'orginfo',       'description' => 'Organisation information' },
      { 'cn' => 'printerqueues', 'description' => 'Printer queues'           },
      { 'cn' => 'servers',       'description' => 'Server information'       },
    ]

    group_specs.each do |system_group|
      self.create(system_group)
    end
  end
end



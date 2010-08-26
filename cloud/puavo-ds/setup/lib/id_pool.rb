class IdPool < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "cn",
                :prefix => "",
                :classes => ['top', 'puavoIdPool'] )

  setup_connection( configurations["puavo"].merge( "base" => "o=puavo" ) )

end

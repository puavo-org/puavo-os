class IdPool < ActiveLdap::Base
  ldap_mapping( :dn_attribute => "cn",
                :prefix => "",
                :classes => ['top', 'puavoIdPool'] )

  setup_connection( configurations["settings"]["ldap_server"].merge( "base" => "o=puavo" ) )

  def self.next_uid_number
    new_uid_number = next_id("puavoNextUidNumber")
    if User.find(:first, :attribute => "uidNumber", :value => new_uid_number)
      return next_uid_number
    end
    return new_uid_number
  end

  def self.next_gid_number
    new_gid_number = next_id("puavoNextGidNumber")
    if Group.find(:first, :attribute => "gidNumber", :value => new_gid_number)
      return next_gid_number
    end
    return new_gid_number
  end

  def self.next_puavo_id
    new_puavo_id = next_id("puavoNextId")
    return new_puavo_id
  end

  private

  def self.next_id(id_field)
    id_pool = self.find('IdPool')
    new_id = id_pool.send(id_field)
    id_pool.send(id_field + "=", new_id + 1)
    id_pool.save
    return new_id.to_s
  end
end

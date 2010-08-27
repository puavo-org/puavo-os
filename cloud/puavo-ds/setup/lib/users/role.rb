class Role < LdapBase
  ldap_mapping( :dn_attribute => "puavoId",
                :prefix => "ou=Roles",
                :classes => ['top',  'puavoUserRole'] )

  has_many :members, :class_name => "User", :wrap => "member", :primary_key => "dn"
  has_many :memberUids, :class_name => "User", :wrap => "memberUid", :primary_key => "uid"

  has_many( :groups,
            :class_name => "Group",
            :wrap => "puavoMemberGroup",
            :primary_key => "dn" )
            

  belongs_to( :school, :class_name => 'School',
              :foreign_key => 'puavoSchool',
              :primary_key => 'dn' )

  before_validation :set_special_ldap_value

  def set_special_ldap_value
    self.puavoId = IdPool.next_puavo_id if self.puavoId.nil?
    self.cn = self.displayName
  end

  def id
    self.puavoId.to_s unless puavoId.nil?
  end

  def add_member(member)
    self.members << member
    self.update_attribute( :memberUid, Array(self.memberUid).push(member.uid) )
  end

  def delete_member(member)
    self.members.delete(member)
    self.memberUids.delete(member)
  end

  def update_associations
    (self.groups.inject([]) { |result, group| result + group.members } | self.members).each do |member|
      member.update_associations
    end
  end
end

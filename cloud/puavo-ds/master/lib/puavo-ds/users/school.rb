class School < BaseGroup
  ldap_mapping( :dn_attribute => "puavoId",
                :prefix => "ou=Groups",
                :classes => ['top','posixGroup','puavoSchool','sambaGroupMapping'] )

  has_many( :members, :class_name => "User",
            :primary_key => 'dn',
            :foreign_key => 'puavoSchool' )
  has_many :user_members, :class_name => "User", :wrap => "member", :primary_key => "dn"
  has_many :user_member_uids, :class_name => "User", :wrap => "memberUid", :primary_key => "uid"

  has_many( :groups, :class_name => 'Group',
            :primary_key => 'dn',
            :foreign_key => 'puavoSchool' )

  has_many( :roles, :class_name => "Role",
            :primary_key => 'dn',
            :foreign_key => 'puavoSchool' )

  # FIXME, Is it better to use human_attribute_name method on the application_helper.rb?
  #def self.human_attribute_name(*args)
  #  if I18n.t("activeldap.attributes").has_key?(:school) &&
  #     # Attribute key name
  #      I18n.t("activeldap.attributes.school").has_key?(args[0].to_sym)
  #    return I18n.t("activeldap.attributes.school.#{args[0]}")
  #  end
  #  super(*args)
  #end
end

# -*- coding: utf-8 -*-
class User < LdapBase
  # Raised by change_ldap_password method when password cannot be changed.
  # Example this happens when kerberos servers is down.
  class PasswordChangeFailed < UserError
  end

  ldap_mapping( :dn_attribute => "puavoId",
                :prefix => "ou=People",
                :classes => ['top', 'posixAccount', 'inetOrgPerson', 'puavoEduPerson','sambaSamAccount','eduPerson'] )
  belongs_to :groups, :class_name => 'Group', :many => 'member', :primary_key => "dn"
  belongs_to :uidGroups, :class_name => 'Group', :many => 'memberUid', :primary_key => "Uid"
  belongs_to( :primary_group, :class_name => 'School',
              :foreign_key => 'gidNumber',
              :primary_key => 'gidNumber' )
  belongs_to( :school, :class_name => 'School',
              :foreign_key => 'puavoSchool',
              :primary_key => 'dn' )
  belongs_to :member_school, :class_name => 'School', :many => 'member', :primary_key => "dn"
  belongs_to :member_uid_school, :class_name => 'School', :many => 'memberUid', :primary_key => "uid"
  belongs_to :roles, :class_name => 'Role', :many => 'member', :primary_key => "dn"
  belongs_to :uidRoles, :class_name => 'Role', :many => 'memberUid', :primary_key => "uid"

  before_validation :set_special_ldap_value

  after_save :set_school_admin

  before_save :is_uid_changed
  after_save :add_member_uid_to_models
  after_save :update_roles
  before_destroy :delete_all_associations
  before_update :change_ldap_password
  after_create :change_ldap_password

  # role_ids/role_name: see set_role_ids_by_role_name and validate methods
  attr_accessor :password, :new_password, :school_admin, :uid_has_changed, :role_ids, :role_name

  validates_confirmation_of :new_password

  OVERWRITE_CHARACTERS = {
    "Ä" => "a",
    "ä" => "a",
    "Ö" => "o",
    "ö" => "o",
    "Å" => "a",
    "å" => "a",
    "é" => "e"
  }

  def validate
    # Role validation
    #
    # The user must have at least one role
    #
    # Set role_ids value by role_name. If get false role_name is invalid.
    if set_role_ids_by_role_name(role_name) == false
      errors.add "Role name"
    # If role_ids is nil: user's role associations not change when save object. Then roles must not be empty!
    # If role_ids is not nil: user's roles value will change when save object. Then role_ids must not be empty!
    elsif (!role_ids.nil? && role_ids.empty?) || ( role_ids.nil? && roles.empty? )
      errors.add_on_blank "Roles"
    else
      # Role must be found by id!
      unless role_ids.nil?
        role_ids.each do |id|
          if Role.find(:first, id).nil?
            errors.add "Role id"
          end
        end
      end
    end

    # puavoEduPersonAffiliation validation
    unless self.class.puavoEduPersonAffiliation_list.include?(puavoEduPersonAffiliation.to_s)
      # User type of user can be set by locale type value.
      # Find locale value and set correct key value to attribute.
      self.class.puavoEduPersonAffiliation_list.each do |value|
        if I18n.t( 'puavoEduPersonAffiliation_' + value ).downcase == puavoEduPersonAffiliation.to_s.downcase
          self.puavoEduPersonAffiliation = value
          break
        end
      end
      unless self.class.puavoEduPersonAffiliation_list.include?(puavoEduPersonAffiliation.to_s)
        errors.add "User type"
      end
    end
  end

  def self.authenticate(login, password)
    logger.debug "Find user by uid from ldap"
    logger.debug "uid: #{login}"

    begin
      user = User.find(:first, :attribute => "uid", :value => login)

      if user.bind(password)
        host = LdapBase.configuration[:host]
        base = LdapBase.base.to_s
        LdapBase.ldap_setup_connection(host, base, user.dn, password)

        # Allow authetication only if user is School Admin in the some School or organisation owner.
        if School.find( :first, :attribute => "puavoSchoolAdmin", :value => user.dn ) ||
            LdapOrganisation.first.owner.include?(user.dn)
          return user
        end
      end
    rescue
      logger.info "Login failed: login: #{login}"
      return false
    end     
  end

  def change_ldap_password
    unless new_password.nil? || new_password.empty?
      ldap_conf = User.configuration
      system( 'ldappasswd', '-Z',
              '-h', ldap_conf[:host],
              '-D', ldap_conf[:bind_dn],
              '-w', ldap_conf[:password],
              '-s', new_password,
              dn.to_s )
      if $?.exitstatus != 0
        raise PasswordChangeFailed, I18n.t('flash.password.failed')
      end
    end
  end

  def self.import_columns
    ["givenName", "sn", "uid", "new_password", "role_name", "puavoEduPersonAffiliation"]
  end

  # FIXME, where is better location on this method? Using same code also on other model?
  def self.human_attribute_name(*args)
    if I18n.t("activeldap.attributes").has_key?(:user) &&
       # Attribute key name
       I18n.t("activeldap.attributes.user").has_key?(args[0].to_sym)
      return I18n.t("activeldap.attributes.user.#{args[0]}")
    end
    super(*args)
  end

  #
  # Retruns the array (users). 
  #
  # Example of Data: {"0"=>["Wilk", "Mabey"], "1"=>["Ben", "Joseph"], "2"=>["Class 4", "Class 4"]}
  # Example of Columns: {"0" => "Lastname", "1" => "Given names", "2" => "Group" }
  # 
  def self.hash_array_data_to_user(data, columns, school)
    users = []
    max_data_column_number = data.keys.max { |a,b| a.to_i <=> b.to_i }
    # Row contains one user data (row number == user_index)
    0.upto data["0"].length-1 do |user_index|
      user = Hash.new
      0.upto max_data_column_number.to_i do |column_index|
        user[columns[column_index]] = data[column_index.to_s][user_index]
      end
      new_user = User.new(user)
      new_user.puavoSchool = school.dn
      users.push new_user
    end

    return users
  end

  def self.validate_users(users)
    valid = []
    invalid = []
    users.each do |user|
      if  user.uid.nil? or user.uid.empty?
        user.generate_username
      end
      user.valid? ? (valid.push user) : (invalid.push user)
    end
    return { :valid => valid, :invalid => invalid }
  end

  #
  # Return array. This array includes arrays of users, one per role
  #
  def self.list_by_role(users)
    users_by_role = []
    roles_by_name = users.map {|user| user.roles.first.displayName}.uniq
    roles_by_name.each do |role_name|
      users_by_role.push users.select {|u| u.roles.first.displayName == role_name}
    end
    return users_by_role
  end
  def generate_password
    characters = (("a".."z").to_a + ("0".."9").to_a).delete_if do |char| not char[/[015iIosq]/].nil? end
    self.new_password = Array.new(8) { characters[rand(characters.size)] }.join
  end

  def self.puavoEduPersonAffiliation_list
    ["teacher", "staff", "student", "visitor", "parent", "admin"]
  end

  def id
    self.puavoId.to_s unless self.puavoId.nil?
  end

  # Update user's role list by role_ids
  def update_roles
    unless self.role_ids.nil?
      add_roles = self.role_ids
      delete_roles = ( Role.all.map{ |p| p.id.to_s } - add_roles )
      user_role_ids = self.roles.map{ |p| p.id.to_s }
      
      # Add roles
      ( add_roles - user_role_ids ).each do |role_id|
        Role.find(role_id).add_member(self)
      end
      
      # Delete roles
      ( user_role_ids & delete_roles ).each do |role_id|
        Role.find(role_id).delete_member(self)
      end
      
      self.reload
      self.update_associations
    end
  end


  def generate_username
    self.uid = username_escape(self.givenName).to_s + "." + username_escape(self.sn).to_s
  end

  def username_escape(string)
    string.strip.split(//).map do |char|
      OVERWRITE_CHARACTERS.has_key?(char) ? OVERWRITE_CHARACTERS[char] : char
    end.join.downcase.gsub(/[^a-z]/, '')
  end

  # Update User - Group association by roles
  def update_associations
    new_group_list =
      self.roles.inject([]) do |result, role|
      result + role.groups
    end

    # add groups
    (new_group_list - self.groups).each do |group|
      logger.debug "Add group (#{self.cn.to_s}): " + group.cn.to_s
      group.members << self
      group.memberUids << self
    end

    # delete groups
    (self.groups - new_group_list).each do |group|
      logger.debug "Delete group (#{self.cn.to_s}): " + group.cn.to_s
      group.members.delete(self)
      group.memberUids.delete(self)
    end
  end

  def human_readable_format(attribute)
    case attribute
    when "role_ids"
      self.send(attribute).map do |id|
        Role.find(id).displayName
      end
    when "puavoEduPersonAffiliation"
      if self.class.puavoEduPersonAffiliation_list.include?(self.send(attribute).to_s)
        I18n.t( 'puavoEduPersonAffiliation_' + self.send(attribute) )
      else
        self.send(attribute).to_s
      end
    else
      self.send(attribute).to_s
    end
  end

  private

  # Find role object by name (role_name) and set id to role_ids array.
  #
  # set_role_ids_by_role_name method is run when validate object (see "validate" method).
  #
  # update_roles method run after save. update_roles join roles to user by role id (role_ids).
  #
  # This makes it possible for that you can also set user's role by name.
  # user = User.first
  # user.role_name = "Administrator"
  # user.save
  def set_role_ids_by_role_name(name)
    unless role_name.nil?
      role  = Role.find(:first, :attribute => "displayName", :value => name)
      if role.nil?
        return false
      else
        self.role_ids = Array(role.id)
      end
    end
    return true
  end

  def set_special_ldap_value
    self.displayName = self.givenName + " " + self.sn
    self.cn = self.uid
    self.homeDirectory = "/home/" + self.school.cn + "/" + self.uid unless self.uid.nil?
    self.gidNumber = self.school.gidNumber unless self.puavoSchool.nil?
    set_uid_number if self.uidNumber.nil?
    self.puavoId = IdPool.next_puavo_id if self.puavoId.nil?
    set_samba_settings if self.sambaSID.nil?
    unless self.gidNumber.nil? || self.puavoSchool.nil?
      self.sambaPrimaryGroupSID = "#{SambaDomain.first.sambaSID}-#{self.school.puavoId}"
    end
    self.gecos = self.displayName + ',,,'
    self.loginShell = '/bin/bash'
  end

  def set_uid_number
    self.uidNumber = IdPool.next_uid_number
  end

  def set_school_admin
    if self.school_admin == "true"
      self.school.puavoSchoolAdmin = Array(self.school.puavoSchoolAdmin).push self.dn
      self.school.save
    end
  end

  def is_uid_changed
    unless self.puavoId.nil?
      begin
        old_user = User.find(self.puavoId)
        if self.uid != old_user.uid
          self.uid_has_changed = true
          logger.debug "User uid has changed. Remove memberUid from roles and groups"
          Role.find( :all,
                        :attribute => "memberUid",
                        :value => old_user.uid ).each do |role|
            role.memberUids.delete(old_user)
          end
          Group.find( :all,
                      :attribute => "memberUid",
                      :value => old_user.uid ).each do |group|
            group.memberUids.delete(old_user)
          end
          School.find( :all,
                       :attribute => "memberUid",
                       :value => old_user.uid ).each do |school|
            school.user_member_uids.delete(old_user)
          end

        end
      rescue ActiveLdap::EntryNotFound
      end
    end
  end

  def add_member_uid_to_models
    if self.uid_has_changed
      logger.debug "User uid has changed. Add new uid to roles and groups if it not exists"
      self.uid_has_changed = false
      self.roles.each do |role|
        role.memberUids << self
      end
      self.groups.each do |group|
        group.memberUids << self
      end
    end
    self.school.user_member_uids << self
    self.school.user_members << self
  end

  private

  def delete_all_associations
    self.school.user_member_uids.delete(self)
    self.school.user_members.delete(self)
    self.roles.each do |p|
      p.delete_member(self)
    end
    self.groups.each do |g|
      g.members.delete(self)
      g.memberUids.delete(self)
    end
  end

  def set_samba_settings 
    self.sambaSID = "#{SambaDomain.first.sambaSID}-#{self.puavoId}"
    self.sambaAcctFlags = "[U]"
  end
end

# FIXME: this code have to move to better place.
module ActiveLdap
  module Association
    class BelongsTo < Proxy
      # Overwrite to_s method.
      # Example usage: user.primary_group.to_s, return example: "Class 4"
      def to_s
        # exists?-method load target (example group object) and returns true if found it
        if self.exists?
          return self.target.to_s
        end
        return ""
      end
    end
  end
end

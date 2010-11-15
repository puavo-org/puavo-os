class UserSession < Authlogic::Session::Base
  include ActiveModel::Conversion

  find_by_login_method :find_or_create_from_ldap
  verify_password_method :valid_ldap_credentials?

  def persisted?
    false
  end
end 

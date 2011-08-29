require "app_responder"

class ApplicationController < ActionController::Base
  self.responder = AppResponder
  respond_to :html
  protect_from_forgery
  layout 'application'
  before_filter :set_organisation, :set_locale, :require_user
  helper_method :current_user_session, :current_user, :puavo_api

  private

  def puavo_api
    if @puavo_api.nil?
      server = session[:organisation].value_by_key('puavo_api_server')
      username = session[:organisation].value_by_key('puavo_api_username')
      password = session[:organisation].value_by_key('puavo_api_password')
      ssl = ( session[:organisation].value_by_key('puavo_api_ssl') == false ? false : true )

      @puavo_api = Puavo::Client::Base.new( server, username, password, ssl )
    end
    return @puavo_api
  end

  def find_school
    if @schools.nil?
      @schools = puavo_api.schools.all
      # Convert rdns entry to string
      owners = puavo_api.organisation.find.owner.map{ |o|
        o["rdns"]}.map{ |g| 
        g.map{|c| 
          c.to_a.join("=")}.join(",") }
      if owners.include?(current_user.dn)
        current_user.role_symbols = [:organisation_owner]
      else
        user_groups = puavo_api.groups.find_all_by_memberUid(current_user.login)
        admin_of_schools = SchoolAdminGroup.where( :group_id => user_groups.map{ |g|
                                                     g.puavoId }).map do |sag|
          sag.school_id
        end
        unless admin_of_schools.empty?
          current_user.role_symbols = [:school_admin]
          current_user.admin_of_schools = admin_of_schools
        end
      end
    end
    @school = @schools.select{ |s| s.puavoId.to_s == params[:school_id].to_s }.first
  end

  def set_organisation
    logger.info "Request host: #{request.host}"

    if session[:organisation].nil?
      begin
        # Find organisation by request.host.
        # If you don't need multiple organisations you have to only set organisation with:
        # config/organisations.yml
        # default
        #   name: Default organisation
        #   host: *
        session[:organisation] = Organisation.find_by_host(request.host)
        # Find default organisation (host == "*") if request host not found from configurations.
        session[:organisation] = Organisation.find_by_host("*") unless session[:organisation]
        unless session[:organisation]
          # FATAL error
          raise "Organisation does not exist and default organisation is not set."
        end
      rescue
        # FIXME, redirect to login page?
        logger.error $!
        render :text => 'Fatal error while detecting organisation.'
        return false
      end
    else
      logger.info "Organisation in session: %s" % session[:organisation].inspect
      # Compare session host to client host. This is important security check.
      unless session[:organisation].host == request.host || session[:organisation].host == "*"
        # This is a serious problem. Some one trying to hack this system.
        # FIXME, redirect to login page?
        logger.info "request.host doesn't not match to session organisation"
        render :text => "Session error"
        return false
      end
    end

    # Use user's organisation on this request (thread), see lib/organisation.rb
    Organisation.current = session[:organisation]
  end

  def set_locale
    I18n.locale =  Organisation.current.value_by_key('locale') ?
     Organisation.current.value_by_key('locale') : :en
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:error] = t('notices.login_required')
      redirect_to new_user_session_url
      return false
    else
      Authorization.current_user = current_user
      current_user.role_symbols = []
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = t('notices.login_required')
      redirect_to account_url
      return false
    end
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end
  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end

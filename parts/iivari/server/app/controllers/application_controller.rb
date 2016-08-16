require "app_responder"

class ApplicationController < ActionController::Base
  self.responder = AppResponder
  respond_to :html
  protect_from_forgery
  layout 'application'
  before_filter :set_organisation, :set_locale, :require_user, :find_school
  helper_method :current_user_session, :current_user, :puavo_api

  def permission_denied
    flash[:error] = t('notices.not_access')
    redirect_to new_user_session_url
  end

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
    @schools = session[:schools]
    @school = @schools.select{ |s| s.puavo_id.to_s == params[:school_id].to_s }.first
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
    logger.info "Logged in user: login: #{current_user.login}, " +
      "organisation: #{current_user.organisation}, " +
      "dn: #{current_user.dn}" if current_user
    unless current_user
      store_location
      flash[:error] = t('notices.login_required')
      redirect_to new_user_session_url
      return false
    else
      current_user.role_symbols = []
      if session[:owners].nil?
        redirect_to new_user_session_url
        return false
      end
      if session[:owners].include?(current_user.puavo_id)
        logger.debug "Logged in user is organisation owner!"
        current_user.role_symbols = [:organisation_owner]
      else
        admin_of_schools = SchoolAdminGroup.where( :group_id => session[:user_groups].map{ |g|
                                                     g.puavo_id }).map do |sag|
          sag.school_id
        end
        unless admin_of_schools.empty?
          logger.debug "Logged in users is administrator in following schools: " + 
            admin_of_schools.join(",")
          current_user.role_symbols = [:school_admin]
          current_user.admin_of_schools = admin_of_schools
        end
      end
      Authorization.current_user = current_user
      logger.info "Authorization, logged in user's role_symbols: " + current_user.role_symbols.inspect
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

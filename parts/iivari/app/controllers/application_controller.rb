class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'
  before_filter :set_organisation_to_session, :set_locale
  helper_method :current_user_session, :current_user

  private

  def set_organisation_to_session
    if Organisation.current.nil?
      # Find organisation by request.host.
      # If you don't need multiple organisations you have to only set organisation with:
      # config/organisations.yml
      # default
      #   name: Default organisation
      #   host: *
      Organisation.current = Organisation.find_by_host(request.host)
      # Find default organisation (host == "*") if request host not found from configurations.
      Organisation.current = Organisation.find_by_host("*") unless Organisation.current
      unless Organisation.current
        # FATAL error
        # FIXME, redirect to login page?
        render :text => "Can't find organisation."
        return false
      end
    else
      # Compare session host to client host. This is important security check.
      unless Organisation.current.host == request.host || Organisation.current.host == "*"
        # This is a serious problem. Some one trying to hack this system.
        # FIXME, redirect to login page?
        logger.info "Default organisation not found!"
        render :text => "Session error"
        return false
      end
    end
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
      flash[:notice] = t('notices.login_required')
      redirect_to new_user_session_url
      return false
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

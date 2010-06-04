class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'
  before_filter :set_organisation_to_session, :set_locale

  private

  def set_organisation_to_session
    if session[:organisation].nil?
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
        # FIXME, redirect to login page?
        render :text => "Can't find organisation."
        return false
      end
    else
      # Compare session host to client host. This is important security check.
      unless session[:organisation].host == request.host || session[:organisation].host == "*"
        # This is a serious problem. Some one trying to hack this system.
        # FIXME, redirect to login page?
        logger.info "Default organisation not found!"
        render :text => "Session error"
        return false
      end
    end
  end

  def set_locale
    I18n.locale = session[:organisation].value_by_key('locale') ?
    session[:organisation].value_by_key('locale') : :en
  end
end

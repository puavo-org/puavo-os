class UserSessionsController < ApplicationController
  skip_before_filter :require_user, :except => [:destroy]

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save
    session[:schools] = nil
    #logger.debug "User session: %s" % @user_session.inspect
    respond_with(@user_session) do |format|
      if @user_session.errors.any?
        logger.info "Authlogic errors: %s" % @user_session.errors.inspect
        format.html { render :action => :new }
      else
        format.html { redirect_to welcome_url }
      end
    end
  end

  def destroy
    current_user_session.destroy
    redirect_to new_user_session_url
  end
end


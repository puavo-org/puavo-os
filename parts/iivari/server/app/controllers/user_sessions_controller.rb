class UserSessionsController < ApplicationController
  skip_before_filter :require_user, :except => [:destroy]
  skip_before_filter :find_school

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save
    respond_with(@user_session) do |format|
      if @user_session.errors.any?
        logger.info "Authlogic errors: %s" % @user_session.errors.inspect
        format.html { render :action => :new }
      else
        session[:owners] = puavo_api.organisation.find.owners
        session[:schools] = puavo_api.schools.all
        session[:user_groups] = puavo_api.groups.find_all_by_memberUid(current_user.login)
        format.html { redirect_to welcome_url }
      end
    end
  end

  def destroy
    current_user_session.destroy
    session[:owners] = []
    session[:schools] = []
    session[:user_groups] = []
    redirect_to new_user_session_url
  end
end


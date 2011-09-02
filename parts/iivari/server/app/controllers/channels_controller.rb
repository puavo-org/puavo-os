class ChannelsController < ApplicationController
  before_filter :find_school
  filter_access_to :all

  def welcome
    if current_user.role_symbols.include?(:organisation_owner)
      path = channels_path(@schools.first.puavo_id)
    else
      path = channels_path(current_user.admin_of_schools.first)
    end

    respond_to do |format|
      format.html { redirect_to path }
    end
  end

  # GET /channels
  # GET /channels.xml
  def index
    @channels = Channel.with_permissions_to(:manage).find_all_by_school_id(@school.puavo_id)
    respond_with(@channels)
  end

  # GET /channels/1
  # GET /channels/1.xml
  def show
    @channel = Channel.with_permissions_to(:manage).find(params[:id])
    respond_with(@channel)
  end

  # GET /channels/new
  # GET /channels/new.xml
  def new
    @channel = Channel.new
    @channel.slide_delay = 15

    respond_with(@channel)
  end

  # GET /channels/1/edit
  def edit
    @channel = Channel.with_permissions_to(:manage).find(params[:id])
  end

  # POST /channels
  # POST /channels.xml
  def create
    @channel = Channel.new(params[:channel])
    @channel.theme = "gold"
    @channel.school_id = @school.puavo_id
    @channel.save
    respond_with(@channel) do |format|
      format.html{ redirect_to( channel_path(@school.puavo_id, @channel) ) }
    end
  end

  # PUT /channels/1
  # PUT /channels/1.xml
  def update
    @channel = Channel.with_permissions_to(:manage).find(params[:id])
    @channel.update_attributes(params[:channel])

    respond_with(@channel) do |format|
      format.html{ redirect_to( channel_path(@school.puavo_id, @channel) ) }
    end
  end

  # DELETE /channels/1
  # DELETE /channels/1.xml
  def destroy
    @channel = Channel.with_permissions_to(:manage).find(params[:id])
    @channel.destroy
    respond_with(@channel)
  end
end

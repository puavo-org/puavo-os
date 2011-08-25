class ChannelsController < ApplicationController
  before_filter :find_school

  def wellcome
    @school = @schools.first
    respond_to do |format|
      format.html { redirect_to channels_path(@school.puavoId) }
    end
  end

  # GET /channels
  # GET /channels.xml
  def index
    @channels = Channel.find_all_by_school_id(@school.puavoId)
    respond_with(@channels)
  end

  # GET /channels/1
  # GET /channels/1.xml
  def show
    @channel = Channel.find(params[:id])
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
    @channel = Channel.find(params[:id])
  end

  # POST /channels
  # POST /channels.xml
  def create
    @channel = Channel.new(params[:channel])
    @channel.theme = "gold"
    @channel.school_id = @school.puavoId
    @channel.save
    respond_with(@channel) do |format|
      format.html{ redirect_to( channel_path(@school.puavoId, @channel) ) }
    end
  end

  # PUT /channels/1
  # PUT /channels/1.xml
  def update
    @channel = Channel.find(params[:id])
    @channel.update_attributes(params[:channel])

    respond_with(@channel) do |format|
      format.html{ redirect_to( channel_path(@school.puavoId, @channel) ) }
    end
  end

  # DELETE /channels/1
  # DELETE /channels/1.xml
  def destroy
    @channel = Channel.find(params[:id])
    @channel.destroy
    respond_with(@channel)
  end
end

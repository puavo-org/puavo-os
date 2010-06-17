class ChannelsController < ApplicationController
  before_filter :require_user
  respond_to :html

  def wellcome
    @channel = Channel.first
    redirect_to channel_slides_path(@channel)
  end

  # GET /channels
  # GET /channels.xml
  def index
    @channels = Channel.all
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
    @channel.save
    respond_with(@channel)
  end

  # PUT /channels/1
  # PUT /channels/1.xml
  def update
    @channel = Channel.find(params[:id])
    @channel.update_attributes(params[:channel])
    respond_with(@channel)
  end

  # DELETE /channels/1
  # DELETE /channels/1.xml
  def destroy
    @channel = Channel.find(params[:id])
    @channel.destroy
    respond_with(@channel)
  end
end

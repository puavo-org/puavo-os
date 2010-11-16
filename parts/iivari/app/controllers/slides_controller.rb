class SlidesController < ApplicationController
  before_filter :require_user
  uses_tiny_mce

  before_filter :find_channel

  # GET /slides
  # GET /slides.xml
  def index
    @slides = @channel.slides.order("position")
    respond_with(@slides)
  end

  # GET /slides/1
  # GET /slides/1.xml
  def show
    @slide = Slide.find(params[:id])

    @next = @channel.slides.where( :position => @slide.position + 1 ).first
    @previous = @channel.slides.where( :position => @slide.position - 1 ).first

    respond_with(@slide)
  end

  # GET /slides/new
  # GET /slides/new.xml
  def new
    @slide = Slide.new
    @slide.template = params[:template] if params.has_key?(:template)

    @partial = params[:template] ? "form" : 'template'

    respond_with(@slide)
  end

  # GET /slides/1/edit
  def edit
    @slide = Slide.find(params[:id])
  end

  # POST /slides
  # POST /slides.xml
  def create
    @slide = Slide.new(params[:slide])
    if params[:slide][:image]
      image = Image.find_or_create(params[:slide][:image])
      @slide.image = image.key
    end
    @slide.channel_id = @channel.id
    @slide.save

    respond_with(@slide) do |format|
      format.html { redirect_to channel_slide_path(@channel, @slide) }
    end
  end

  # PUT /slides/1
  # PUT /slides/1.xml
  def update
    @slide = Slide.find(params[:id])
    if params[:slide][:image]
      image = Image.find_or_create(params[:slide][:image])
      @slide.image = image.key
    end

    params[:slide].delete(:image)
    @slide.update_attributes(params[:slide])

    respond_with(@slide) do |format|
      format.html { redirect_to channel_slide_path(@channel, @slide) }
    end
  end

  # DELETE /slides/1
  # DELETE /slides/1.xml
  def destroy
    @slide = Slide.find(params[:id])
    @slide.destroy
    respond_with(@slide) do |format|
      format.html { redirect_to channel_slides_path(@channel) }
    end
  end

  def sort
    @slides = @channel.slides

    @slides.each do |slide|
      slide.position = params['slide'].index(slide.id.to_s) + 1
      slide.save
    end
    
    render :nothing => true
  end

  private

  def find_channel
    # FIXME, find channel by screen_key
    if params[:channel_id]
      @channel = Channel.find(params[:channel_id])
    else
      @channel = Channel.first
    end
  end
end

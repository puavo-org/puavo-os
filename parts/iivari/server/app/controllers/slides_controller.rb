class SlidesController < ApplicationController
  respond_to :html, :js
  uses_tiny_mce

  before_filter :find_channel
  filter_access_to( :index, :create, :new, :sort,
                    :attribute_check => true,
                    :load_method => lambda { @channel } )
  filter_access_to( :show, :update, :edit, :destroy, :slide_status, :toggle_status,
                    :attribute_check => true )

  # GET /slides
  # GET /slides.xml
  def index
    @slides = @channel.slides
    respond_with(@slides)
  end

  # GET /slides/1
  # GET /slides/1.xml
  def show
    @slide = Slide.find(params[:id])

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
      format.html { redirect_to channel_slide_path(@school.puavo_id, @channel, @slide) }
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
      format.html { redirect_to channel_slide_path(@school.puavo_id, @channel, @slide) }
    end
  end

  # DELETE /slides/1
  # DELETE /slides/1.xml
  def destroy
    @slide = Slide.find(params[:id])
    @slide.destroy
    respond_with(@slide) do |format|
      format.html { redirect_to channel_slides_path(@school.puavo_id, @channel) }
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

  # GET /channels/1/slides/1/slide_status.js
  def slide_status
    @slide = Slide.find(params[:id])

    respond_with([@channel, @slide])
  end

  # PUT /channels/1/slides/1/toggle_status.js
  def toggle_status
    @slide = Slide.find(params[:id])
    @slide.toggle(:status)
    @slide.save
    
    respond_with([@channel, @slide]) do |format|
        format.js { render :action => :slide_status }
    end
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

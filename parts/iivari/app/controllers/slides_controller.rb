class SlidesController < ApplicationController
  layout :determine_layout
  respond_to :html, :json
  uses_tiny_mce

  before_filter :find_channel

  # GET /slides
  # GET /slides.xml
  def index
    @slides = Slide.all
    respond_with(@slides) do |format|
      format.json do
        render :json => @slides.to_json(:only => [:id], :methods => :slide_html)
      end
    end
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

    @partial = params[:template] ? "template_" + params[:template] : 'template'

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
    @slide.image = ImageFile.save(params[:slide][:image]) if params[:slide][:image]
    @slide.save
    respond_with([@channel, @slide])
  end

  # PUT /slides/1
  # PUT /slides/1.xml
  def update
    @slide = Slide.find(params[:id])
    @slide.image = ImageFile.save(params[:slide][:image]) if params[:slide][:image]
    params[:slide].delete(:image)

    @slide.update_attributes(params[:slide])
    respond_with([@channel, @slide])
  end

  # DELETE /slides/1
  # DELETE /slides/1.xml
  def destroy
    @slide = Slide.find(params[:id])
    @slide.destroy
    respond_with([@channel, @slide])
  end

  # GET /:client_key/slides
  def client
  end

  # GET /:client_key/client.manifest
  def manifest
    body = ["CACHE MANIFEST"]
    
    # FIXME
    body << "# zo36ld9k4ajd2io20dmzsdds"

    root = Rails.public_path
    # FIXME, adds only the necessary files
    files = Dir[
                "#{root}/stylesheets/**/*.css",
                "#{root}/javascripts/**/*.js",
                "#{root}/images/**"]
    
    files.each do |file|
      body << "/" +  Pathname(file).relative_path_from( Pathname(root) ).to_s
    end

    body << "slides"
    ImageFile.urls.each do |url|
      body << url
    end

    body << ""
    body << "NETWORK:"
    body << "/"
    body << ""

    render :text => body.join("\n"), :content_type => "text/cache-manifest"
  end

  def image
    expires_in 15.minutes, :public => true
    data_string = ImageFile.find(params[:image]).readlines
    # FIXME image_name?
    send_data data_string, :filename => params[:image_name], :type => 'image/png', :disposition => 'inline'
  end

  private

  def determine_layout
    action_name == "client" ? "client" : "application"
  end

  def find_channel
    @channel = Channel.find(params[:channel_id])
  end
end

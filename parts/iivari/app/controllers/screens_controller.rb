class ScreensController < ApplicationController
  layout :determine_layout
  respond_to :html, :json
  uses_tiny_mce

  # GET /screens
  # GET /screens.xml
  def index
    @screens = Screen.all
    respond_with(@screens) do |format|
      format.json do
        render :json => @screens.to_json(:only => [:id], :methods => :screen_html)
      end
    end
  end

  # GET /screens/1
  # GET /screens/1.xml
  def show
    @screen = Screen.find(params[:id])
    respond_with(@screen)
  end

  # GET /screens/new
  # GET /screens/new.xml
  def new
    @screen = Screen.new

    @partial = params[:template] ? "template_" + params[:template] : 'template'

    respond_with(@screen)
  end

  # GET /screens/1/edit
  def edit
    @screen = Screen.find(params[:id])
  end

  # POST /screens
  # POST /screens.xml
  def create
    @screen = Screen.new(params[:screen])
    @screen.image = ImageFile.save(params[:screen][:image]) if params[:screen][:image]
    @screen.save
    respond_with(@screen)
  end

  # PUT /screens/1
  # PUT /screens/1.xml
  def update
    @screen = Screen.find(params[:id])
    @screen.image = ImageFile.save(params[:screen][:image]) if params[:screen][:image]
    params[:screen].delete(:image)
    @screen.update_attributes(params[:screen])
    respond_with(@screen)
  end

  # DELETE /screens/1
  # DELETE /screens/1.xml
  def destroy
    @screen = Screen.find(params[:id])
    @screen.destroy
    respond_with(@screen)
  end

  # GET /:client_key/screens
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

    body << "screens"
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
end

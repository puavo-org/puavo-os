class ScreenController < ApplicationController
  respond_to :html, :json
  layout "screen"

  # GET /:screen_key/slides.json
  def slides
    # FIXME, @channel will be set by screen_key value
    @channel = Channel.first

    if params[:slide_id]
      @slides = Array(Slide.find(params[:slide_id]))
    else
      # FIXME
      # Right Way:
      # @slides = @channel.slides.order("position")
      # Bug! This does not work. Gives the following error:
      # ActiveSupport::JSON::Encoding::CircularReferenceError (object references itself)
       @slides = Slide.find(:all, :conditions => ["channel_id = ?", @channel.id], :order => "position")
    end

    @slides.each do |slide|
      slide.slide_html = slide_to_screen_html(params[:resolution], slide)
    end

    respond_with(@slides) do |format|
      format.json do
        render :json => @slides.to_json(:only => [:id], :methods => :slide_html)
      end
    end
  end

  # GET /:screen_key/conductor
  # GET /:screen_key/conductor?cache=false&slide_id=40
  # Main page for Iivari client
  def conductor
    @cache = "true"
    url_params = []

    if params[:slide_id]
      # FIXME, slid_id security check?!
      url_params.push "slide_id=#{params[:slide_id]}"
    end
    if params[:resolution]
      url_params.push "resolution=#{params[:resolution]}"
    end
    if params[:cache] && params[:cache] == "false"
      @cache = "false"
    end

    @json_url = "slides.json"
    unless url_params.empty?
      @json_url += "?" + url_params.join("&")
    end

    respond_to do |format|
      format.html
    end
  end

  # GET /:screen_key/screen.manifest
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
    # FIXME, only allowed channels
    Slide.image_urls(Channel.first, params[:resolution]).each do |url|
      body << url
    end

    body << ""
    body << "NETWORK:"
    body << "/"
    body << ""

    render :text => body.join("\n"), :content_type => "text/cache-manifest"
  end

  # GET /:screen_key/image/:image
  def image
    expires_in 15.minutes, :public => true
    if image = Image.find_by_key(params[:image])
      data_string = image.data_by_resolution(params[:template], params[:resolution])
      # FIXME image name?
      send_data data_string, :filename => image.key, :type => image.content_type, :disposition => 'inline'
    else
      render :nothing => true
    end
  end

  private

  def slide_to_screen_html(resolution, slide)
    @resolution = resolution
    @slide = slide
    render_to_string( :partial => "client_" + slide.template + ".html.erb" )
  end
end

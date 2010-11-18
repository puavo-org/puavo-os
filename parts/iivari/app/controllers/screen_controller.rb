class ScreenController < ApplicationController
  respond_to :html, :json
  layout "screen"
  before_filter :auth_recuire, :except => :authentication

  # GET /slides.json
  def slides
    if (@display && @display.active && @channel) || @preview
      if params[:slide_id]
        @slides = Array(Slide.find(params[:slide_id]))
      else
        @slides = @channel.slides.order("position")
      end
    else
      @slides = Array.new
      slide = Slide.new
      slide.body = t('display_non_active_body')
      slide.template = "only_text"
      @slides.push slide
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

  # GET /conductor
  # GET /conductor?cache=false&slide_id=40
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
    if params[:preview]
      url_params.push "preview=#{params[:preview]}"

      if params[:channel_id]
        url_params.push "channel_id=#{params[:channel_id]}"
      end
    end

    @json_url = "slides.json"
    unless url_params.empty?
      @json_url += "?" + url_params.join("&")
    end

    respond_to do |format|
      format.html
    end
  end

  # GET /screen.manifest
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

    body << "conductor?resolution=#{params[:resolution]}"
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

  # GET /image/:image
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

  def authentication
    session[:display_authentication] = true
    session[:hostname] = params[:hostname] if params[:hostname]

    respond_to do |format|
      format.html { redirect_to conductor_screen_path( :resolution => params[:resolution] ) }
    end
  end

  private

  def slide_to_screen_html(resolution, slide)
    @resolution = resolution
    @slide = slide
    layout = slide.template == "web_page" ? "web_page_slide" : "slide"
    render_to_string( "client_" + slide.template + ".html.erb", :layout => layout )
  end

  def auth_recuire
    if params[:preview]
      if require_user != false
        @preview = true
        @channel = Channel.find(params[:channel_id]) if params[:channel_id]
      end
    else
      if session[:display_authentication]
        @display = Display.find_or_create_by_hostname(session[:hostname])
        @channel = @display.active ? @display.channel : nil
      else
        render :json => "Unauthorized", :status => :unauthorized
      end
    end
  end
end

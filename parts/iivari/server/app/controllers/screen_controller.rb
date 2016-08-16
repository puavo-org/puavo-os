class ScreenController < ApplicationController
  skip_before_filter :require_user, :find_school
  respond_to :html, :json
  layout "screen"
  before_filter :auth_require, :except => :displayauth
  after_filter :persist_session
  
  # GET /slides.json?resolution=800x600
  def slides
    if (@display && @display.active && @channel) || preview?
      if params[:slide_id]
        # FIXME, slid_id security check?!
        @slides = Array(Slide.find(params[:slide_id]))
      else
        @slides = @channel.slides
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
        render :json => @slides.to_json( :only => [:id, :status],
                                         :methods => [:slide_html, :timers, :slide_delay])
      end
    end
  end

  # GET /conductor?resolution=800x600&hostname=examplehost
  # GET /conductor?cache=false&slide_id=40
  # Main page for Iivari client
  def conductor
    @cache = "true"
    url_params = []

    if params[:slide_id]
      url_params.push "slide_id=#{params[:slide_id]}"
    end
    if params[:resolution]
      url_params.push "resolution=#{params[:resolution]}"
    end
    if params[:cache] && params[:cache] == "false"
      @cache = "false"
    end
    if params[:channel_id]
      url_params.push "channel_id=#{params[:channel_id]}"
    end

    @json_url = "slides.json"
    unless url_params.empty?
      @json_url += "?" + url_params.join("&")
    end
    
    respond_to do |format|
      format.html
    end
  end

  # GET /screen.manifest?resolution=800x600
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
      body << root_path +  Pathname(file).relative_path_from( Pathname(root) ).to_s
    end

    body << root_path + "conductor?resolution=#{params[:resolution]}&hostname=#{session[:hostname]}"

    Slide.image_urls(@channel, params[:resolution]).each do |url|
      body << root_path + url
    end

    body << ""
    body << "NETWORK:"
    body << "/"
    body << ""

    render :text => body.join("\n"), :content_type => "text/cache-manifest"
  end

  # GET /image/only_image/e59e7f6a488088e675b3736681abf2ef55ce69d28360903cb56fa8cfb69c9155?resolution=800x600
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

  # GET /displayauth?resolution=1366x768&hostname=infotv-01
  def displayauth
    respond_to do |format|
      if params[:hostname]
        session[:display_authentication] = true 
        session[:hostname] = params[:hostname] if params[:hostname]
        format.html { redirect_to conductor_screen_path( :resolution => params[:resolution] ) }
      else
        format.html { render :inline => "Unauthorized", :status => :unauthorized }
      end
    end
  end

  private

  def slide_to_screen_html(resolution, slide)
    @resolution = resolution
    @slide = slide
    layout = (@channel && @channel.theme?) ? "slide_#{@channel.theme}" : "slide_gold"

    render_to_string( "client_" + slide.template + ".html.erb", :layout => layout )
  end

  def auth_require
    if preview?
      require_user
      @channel = Channel.find(params[:channel_id]) if params[:channel_id]
      @channel = Slide.find(params[:slide_id]).channel if params[:slide_id]
    else
      logger.info "Display request"
      if session[:display_authentication]
        @display = Display.find_or_create_by_hostname(session[:hostname])
        @channel = @display.active ? @display.channel : nil
        logger.info "Client hostname: #{@display.hostname}"
      else
        respond_to do |format|
          format.html { redirect_to display_authentication_path( :resolution => params[:resolution],
                                                                 :hostname => params[:hostname] ) }
          format.json { render :json => "Unauthorized", :status => :unauthorized }
        end
      end
    end
  end

  def preview?
    session.has_key?(:user_credentials) ? true : false
  end

  def persist_session
    env["rack.session.options"][:expire_after] = 20.years if session[:display_authentication]
  end
end

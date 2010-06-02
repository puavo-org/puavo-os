class ScreenController < ApplicationController
  respond_to :html, :json
  layout "screen"

  # GET /slides
  # GET /slides.xml
  def slides
    @channel = Channel.first
    @slides = @channel.slides
    respond_with(@slides) do |format|
      format.json do
        render :json => @slides.to_json(:only => [:id], :methods => :slide_html)
      end
    end
  end

  # GET /:screen_key/slides
  # Main page for Iivari client
  def conductor
  end

  # GET /:screen_key/client.manifest
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

end

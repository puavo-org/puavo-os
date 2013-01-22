class Image < ActiveRecord::Base

  after_destroy :remove_image_file

  def self.find_or_create(data)
    image_data = data.read
    key = Digest::SHA2.hexdigest(image_data)
    image = Image.find_by_key(key)
    if image.nil?
      image = Image.create(:key => key, :content_type => data.content_type)
      File.open( Image.path + "/" + image.key, "wb") { |f| f.write(image_data) }
    end

    return image
  end

  def data_by_resolution(template, resolution)
    (screen_width, screen_height) = resolution.split("x")
    if template == "only_image"
      max_width = (screen_width.to_f * 8.0 / 9.0).to_i
    else
      max_width = (screen_width.to_f * 2.0 / 5.0).to_i
    end
    max_height = (screen_height.to_f * 6.0 / 8.0).to_i

    filename = "#{Image.path}/#{self.key}_#{max_width}x#{max_height}"

    unless File.exists?( filename )
      # Create new scale image
      scale_new_image_file(max_width, max_height)
    end
    return File.readlines( filename )
  end

  def self.path
    (Rails.root. + "slide_images").to_s
  end

  private

  def scale_new_image_file(max_width, max_height)
    image_orig = Magick::Image.read("#{Image.path}/#{self.key}" ).first
    image_scale = image_orig.auto_orient.resize_to_fit(max_width,max_height)
    filename = "#{Image.path}/#{self.key}_#{max_width}x#{max_height}"
    File.open( filename, "wb") { |f| f.write(image_scale.to_blob) }
  end

  def remove_image_file
    if !self.key.nil? && !self.key.empty?
      Dir.new( Image.path + "/").each  do |file|
        if file.match(/^#{self.key}/)
          File.delete( Image.path + "/" + file )
        end
      end
    end
  end
end

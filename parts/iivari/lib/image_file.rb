require "digest/sha2"

class ImageFile

  def self.save(data)
    image = data.read
    image_name = Digest::SHA2.hexdigest(image)
    File.open( self.path(image_name), "wb") { |f| f.write(image) }
    return image_name
  end

  def self.find(image_name, resolution)
    begin
      return File.open( self.path(image_name) )
    rescue
      return false
    end
  end

  def self.urls(resolution)
    Dir[ "#{self.path}/*"].map do |file|
      "image/" +
        Pathname(file).relative_path_from( Pathname(self.path) ).to_s + "?resolution=#{resolution}"
    end
  end

  private

  def self.path(image_name = nil)
    Rails.root + "slide_images" +
      ( image_name ? image_name : "" )
  end
end

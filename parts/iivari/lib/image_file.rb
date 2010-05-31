class ImageFile

  def self.save(screen_id, data)
    File.open( self.path(screen_id), "wb") { |f| f.write(data.read) }
  end

  def self.find(screen_id)
    begin
      return File.open( self.path(screen_id) )
    rescue
      return false
    end
  end

  def self.urls
    Dir[ "#{self.path}/*"].map do |file|
      "screens/" +
        Pathname(file).relative_path_from( Pathname(self.path) ).to_s +
        "/image"
    end
  end

  private

  def self.path(screen_id = nil)
    Rails.root + "screen_images" +
      ( screen_id ? screen_id.to_s : "" )
  end
end

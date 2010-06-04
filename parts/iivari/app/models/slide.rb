class Slide < OrganisationData
  belongs_to :channel
  
  acts_as_list

  attr_accessor :slide_html

  def image_url(resolution)
    unless self.image.nil?
      "image/#{self.template}/#{self.image}?resolution=#{resolution}"
    end
  end

  def self.image_urls(channel, resolution)
    channel.slides.inject([]) do |result, s|
      unless s.image.nil?
        result.push s.image_url(resolution)
      end
    end
  end
end

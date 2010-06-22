class Slide < OrganisationData
  belongs_to :channel
  
  acts_as_list

  after_update :set_channel_updated_at
  after_create :set_channel_updated_at

  attr_accessor :slide_html

  def image_url(resolution)
    unless self.image.nil?
      "image/#{self.template}/#{self.image}?resolution=#{resolution}"
    end
  end

  def self.image_urls(channel, resolution)
    channel.slides.inject([]) do |result, s|
      s.image.nil? ? result : ( result.push s.image_url(resolution) )
    end
  end

  def updated_at
    self.channel.updated_at
  end

  protected

  def set_channel_updated_at
    self.channel.updated_at = Time.now
    self.channel.save
  end
end

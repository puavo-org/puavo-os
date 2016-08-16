class Slide < OrganisationData
  belongs_to :channel
  has_many :slide_timers
  
  acts_as_list :scope => :channel

  before_save :fix_http_url, :remove_image_if_needed

  after_update :set_channel_updated_at
  after_create :set_channel_updated_at

  after_destroy :remove_image

  attr_accessor :slide_html

  using_access_control

  def school_id
    channel.school_id
  end

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
    self.channel.updated_at unless self.channel.nil?
  end

  def timers
    return self.slide_timers.map &:to_json
  end

  def slide_delay
    self.channel && self.channel.slide_delay ? self.channel.slide_delay : 15
  end

  protected

  def set_channel_updated_at
    self.channel.updated_at = Time.now
    self.channel.save
  end

  private

  def fix_http_url
    if self.template == "web_page"
      if self.body.match(/http[s]{0,1}:\/\//).nil?
        self.body = "http://#{self.body}"
      end
    end
  end

  # before_save
  def remove_image_if_needed
    if self.created_at? && self.image.nil? == false
      # Remove image if it is not used anywhere
      old_image_key = Slide.find(self.id).image
      if self.image != old_image_key && Slide.where(:image => old_image_key).count == 1
        image = Image.find_by_key(old_image_key)
        unless image.nil?
          image.destroy
        end
      end
    end
  end

  # after_destroy
  def remove_image
    unless self.image.nil?
      # Remove image if it is not used anywhere
      if Slide.where(:image => self.image).empty?
        image = Image.find_by_key(self.image)
        unless image.nil?
          image.destroy
        end
      end
    end
  end
end

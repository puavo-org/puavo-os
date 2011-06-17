class SlideTimer < ActiveRecord::Base
  belongs_to :slide

  after_update :set_channel_updated_at
  after_create :set_channel_updated_at
  after_update :set_channel_updated_at
  before_destroy :set_channel_updated_at

  private

  def set_channel_updated_at
    self.slide.channel.updated_at = Time.now
    self.slide.channel.save
  end
end

class SlideTimer < ActiveRecord::Base
  belongs_to :slide

  after_update :set_channel_updated_at
  after_create :set_channel_updated_at
  after_update :set_channel_updated_at
  before_destroy :set_channel_updated_at

  def school_id
    slide.channel.school_id
  end

  def to_json
    {
      "start_datetime" => json_datetime(self.start_datetime),
      "end_datetime" => json_datetime(self.end_datetime),
      "start_time" => json_datetime(self.start_time),
      "end_time" => json_datetime(self.end_time),
      "weekday_0" => self.weekday_0,
      "weekday_1" => self.weekday_1,
      "weekday_2" => self.weekday_2,
      "weekday_3" => self.weekday_3,
      "weekday_4" => self.weekday_4,
      "weekday_5" => self.weekday_5,
      "weekday_6" => self.weekday_6
    }
  end

  private
  
  # formats the datetime for WebKit JavaScriptCore
  def json_datetime(datetime)
    datetime.getutc.strftime('%Y/%m/%d %H:%M GMT+0000') rescue ""
  end

  def set_channel_updated_at
    self.slide.channel.updated_at = Time.now
    self.slide.channel.save
  end
end

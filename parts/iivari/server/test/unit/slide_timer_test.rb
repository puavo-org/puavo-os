require 'test_helper'

class SlideTimerTest < ActiveSupport::TestCase

  test "timer dates" do
    channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
    assert channel.reload
    
    slide = Slide.create(:channel => channel)
    assert slide.reload
    
    # NOTE: start_time and end_time are datetimes in the database,
    # although the date is never used, only the time.

    # active between 9.15 -> 19.30 @ 1.8.2011 14.00 - 31.8.2011 14.00
    timer = SlideTimer.create(
      :start_datetime => DateTime.new(2011,8,1,14,0),
      :end_datetime => DateTime.new(2011,8,31,14,0),
      :start_time => DateTime.new(1970,1,1,9,15),
      :end_time => DateTime.new(1970,1,1,19,30),
      :weekday_0 => true,
      :weekday_1 => false,
      :weekday_2 => false,
      :weekday_3 => false,
      :weekday_4 => false,
      :weekday_5 => false,
      :weekday_6 => false,
      :slide => slide
      )
    assert timer.reload
    
    channel.reload
    assert_in_delta Time.now, channel.updated_at, 1
    assert_equal 1, slide.timers.size
    
    json = timer.to_json
    assert_equal "2011/08/01 14:00", json['start_datetime']
    assert_equal "2011/08/31 14:00", json['end_datetime']
    assert_equal "1970/01/01 09:15", json['start_time']
    assert_equal "1970/01/01 19:30", json['end_time']
    assert_equal true, json['weekday_0']
    assert_equal false, json['weekday_1']
    assert_equal false, json['weekday_2']
    assert_equal false, json['weekday_3']
    assert_equal false, json['weekday_4']
    assert_equal false, json['weekday_5']
    assert_equal false, json['weekday_6']
  end


  test "timer with undefined dates" do
    channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
    assert channel.reload
    
    slide = Slide.create(:channel => channel)
    assert slide.reload
    
    timer = SlideTimer.create(:slide => slide)
    assert timer.reload
    
    json = timer.to_json
    assert_equal "", json['start_datetime']
    assert_equal "", json['end_datetime']
    assert_equal "", json['start_time']
    assert_equal "", json['end_time']
  end
end

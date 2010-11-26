class AddWeekday0Weekday1Weekday2Weekday3Weekday4Weekday5Weekday6ToSlideTimer < ActiveRecord::Migration
  def self.up
    add_column :slide_timers, :weekday_0, :boolean, :default => true
    add_column :slide_timers, :weekday_1, :boolean, :default => true
    add_column :slide_timers, :weekday_2, :boolean, :default => true
    add_column :slide_timers, :weekday_3, :boolean, :default => true
    add_column :slide_timers, :weekday_4, :boolean, :default => true
    add_column :slide_timers, :weekday_5, :boolean, :default => true
    add_column :slide_timers, :weekday_6, :boolean, :default => true
  end

  def self.down
    remove_column :slide_timers, :weekday_0
    remove_column :slide_timers, :weekday_1
    remove_column :slide_timers, :weekday_2
    remove_column :slide_timers, :weekday_3
    remove_column :slide_timers, :weekday_4
    remove_column :slide_timers, :weekday_5
    remove_column :slide_timers, :weekday_6
  end
end

class CreateSlideTimers < ActiveRecord::Migration
  def self.up
    create_table :slide_timers do |t|
      t.datetime :start_datetime
      t.datetime :end_datetime
      t.datetime :start_time
      t.datetime :end_time
      t.integer :slide_id

      t.timestamps
    end
  end

  def self.down
    drop_table :slide_timers
  end
end

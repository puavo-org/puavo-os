class AddSlideDelayToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :slide_delay, :integer
  end

  def self.down
    remove_column :channels, :slide_delay
  end
end

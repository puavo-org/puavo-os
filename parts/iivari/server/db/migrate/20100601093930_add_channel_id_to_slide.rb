class AddChannelIdToSlide < ActiveRecord::Migration
  def self.up
    add_column :slides, :channel_id, :integer
  end

  def self.down
    remove_column :slides, :channel_id
  end
end

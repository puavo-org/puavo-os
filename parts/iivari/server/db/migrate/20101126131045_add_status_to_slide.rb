class AddStatusToSlide < ActiveRecord::Migration
  def self.up
    add_column :slides, :status, :boolean, :default => true
  end

  def self.down
    remove_column :slides, :status
  end
end

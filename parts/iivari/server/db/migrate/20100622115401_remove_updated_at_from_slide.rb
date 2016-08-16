class RemoveUpdatedAtFromSlide < ActiveRecord::Migration
  def self.up
    remove_column :slides, :updated_at
  end

  def self.down
    add_column :slides, :updated_at, :datetime
  end
end

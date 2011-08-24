class AddSchoolIdToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :school_id, :integer
  end

  def self.down
    remove_column :channels, :school_id
  end
end

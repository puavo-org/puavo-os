class AddPuavoIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :puavo_id, :integer
  end

  def self.down
    remove_column :users, :puavo_id
  end
end

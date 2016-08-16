class AddDnToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :dn, :string
  end

  def self.down
    remove_column :users, :dn
  end
end

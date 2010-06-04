class AddOrganisationToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :organisation, :string
  end

  def self.down
    remove_column :users, :organisation
  end
end

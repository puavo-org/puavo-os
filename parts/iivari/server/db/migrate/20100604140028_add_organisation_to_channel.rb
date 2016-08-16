class AddOrganisationToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :organisation, :string
  end

  def self.down
    remove_column :channels, :organisation
  end
end

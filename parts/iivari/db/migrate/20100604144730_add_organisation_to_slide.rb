class AddOrganisationToSlide < ActiveRecord::Migration
  def self.up
    add_column :slides, :organisation, :string
  end

  def self.down
    remove_column :slides, :organisation
  end
end

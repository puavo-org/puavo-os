class AddTemplateToScreen < ActiveRecord::Migration
  def self.up
    add_column :screens, :template, :string
  end

  def self.down
    remove_column :screens, :template
  end
end

class AddTemplateToSlide < ActiveRecord::Migration
  def self.up
    add_column :slides, :template, :string
  end

  def self.down
    remove_column :slides, :template
  end
end

class AddThemeToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :theme, :string
  end

  def self.down
    remove_column :channels, :theme
  end
end

class AddImageToScreen < ActiveRecord::Migration
  def self.up
    add_column :screens, :image, :string
  end

  def self.down
    remove_column :screens, :image
  end
end

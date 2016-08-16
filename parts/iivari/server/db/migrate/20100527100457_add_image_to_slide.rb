class AddImageToSlide < ActiveRecord::Migration
  def self.up
    add_column :slides, :image, :string
  end

  def self.down
    remove_column :slides, :image
  end
end

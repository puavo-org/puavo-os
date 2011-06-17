class CreateDisplays < ActiveRecord::Migration
  def self.up
    create_table :displays do |t|
      t.boolean :active, :default => false
      t.integer :channel_id
      t.string :hostname
      t.string :organisation

      t.timestamps
    end
  end

  def self.down
    drop_table :displays
  end
end

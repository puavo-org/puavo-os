class CreateSchoolAdminGroups < ActiveRecord::Migration
  def self.up
    create_table :school_admin_groups do |t|
      t.integer :school_id
      t.integer :group_id
      t.string :organisation

      t.timestamps
    end
  end

  def self.down
    drop_table :school_admin_groups
  end
end

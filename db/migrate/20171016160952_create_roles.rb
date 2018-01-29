class CreateRoles < ActiveRecord::Migration[5.1]
  def up
    create_table :roles do |t|
    t.string   :name
    t.timestamps
    end

    add_index :roles, :name

    ActiveRecord::Base.transaction do
      # Organization.create(:domain=>'kth.se', :name=>"KTH")
      # LtiKey.create(:organization_id=>Organization.find_by_name('KTH').id)    
      role = Role.create(:name=>"User")
      role.update_column(:id, 1)

      role = Role.create(:name=>"Student")
      role.update_column(:id, 2)

      role = Role.create(:name=>"Professor")
      role.update_column(:id, 3)

      role = Role.create(:name=>"Teaching Assistant")
      role.update_column(:id, 4)

      role = Role.create(:name=>"Administrator")
      role.update_column(:id, 5)

      role = Role.create(:name=>"Preview")
      role.update_column(:id, 6)

      role = Role.create(:name=>"School Administrator")
      role.update_column(:id, 9)
    end
  end

  def down
    drop_table :roles   
  end
end

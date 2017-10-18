class CreateUsersRoles < ActiveRecord::Migration[5.1]
  def up
    create_table :users_roles do |t|
		t.integer  :role_id
		t.integer  :user_id    	
      t.timestamps
    end
  end
  def down 
  	drop_table :users_roles
  end
end

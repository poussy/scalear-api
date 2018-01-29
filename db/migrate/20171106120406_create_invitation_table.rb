class CreateInvitationTable < ActiveRecord::Migration[5.1]
  def up
    create_table :invitations do |t|
      t.integer :user_id
      t.integer :course_id
      t.integer :role_id
      t.string :email
      
      t.timestamps
    end
    add_index :invitations, :user_id
    add_index :invitations, :course_id
    add_index :invitations, :email
  end

  def down
    drop_table :invitations
  end
end

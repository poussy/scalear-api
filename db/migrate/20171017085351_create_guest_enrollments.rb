class CreateGuestEnrollments < ActiveRecord::Migration[5.1]
  def up
    create_table :guest_enrollments do |t|
      t.integer  :user_id     
      t.integer  :course_id
      t.timestamps
    end
    add_index :guest_enrollments, :course_id
    add_index :guest_enrollments, :user_id    
  end

  def down 
    drop_table :guest_enrollments
  end
end

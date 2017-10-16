class CreateEnrollments < ActiveRecord::Migration[5.1]
  def change
    create_table :enrollments do |t|
		t.integer  :user_id    	
		t.integer  :course_id
		t.boolean  :email_due_date

      t.timestamps
    end
    add_index :enrollments, :course_id
    add_index :enrollments, :user_id    
  end

  def down 
  	drop_table :enrollments
  end
end

class CreateTeacherEnrollments < ActiveRecord::Migration[5.1]
  def up
    create_table :teacher_enrollments do |t|
		t.integer  :user_id    	
		t.integer  :course_id
		t.string  :role
		t.boolean :email_discussion

      t.timestamps
    end
    add_index :teacher_enrollments, :course_id
    add_index :teacher_enrollments, :user_id    
  end

  def down 
  	drop_table :teacher_enrollments
  end
end

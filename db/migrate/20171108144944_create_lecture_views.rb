class CreateLectureViews < ActiveRecord::Migration[5.1]
	def up
		create_table :lecture_views do |t|
			t.integer :user_id
			t.integer :lecture_id
			t.integer :group_id
			t.integer :course_id
			t.integer :percent

			t.timestamps
		end

		add_index :lecture_views, [ :course_id ,:created_at ]
		add_index :lecture_views, [ :course_id ,:updated_at ]
		add_index :lecture_views, :course_id
		add_index :lecture_views, :group_id
		add_index :lecture_views, :lecture_id
		add_index :lecture_views, :user_id
		add_index :lecture_views, :updated_at 
		add_index :lecture_views, :created_at
	end

	def down
		drop_table :lecture_views		
	end  
end

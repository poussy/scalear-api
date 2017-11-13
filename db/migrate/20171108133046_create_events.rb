class CreateEvents < ActiveRecord::Migration[5.1]
	def up
		create_table :events do |t|
			t.string   :name
			t.datetime :start_at
			t.datetime :end_at
			t.string   :color
			t.boolean  :all_day
			t.integer  :group_id
			t.integer  :quiz_id
			t.integer  :lecture_id
			t.integer  :course_id

			t.timestamps
		end
		add_index :events, :course_id
		add_index :events, :group_id 
		add_index :events, :lecture_id
		add_index :events, :quiz_id
	end

	def down
		drop_table :events		
	end  
end

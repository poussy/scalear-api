class CreateVideoNotes < ActiveRecord::Migration[5.1]
	def up
		create_table :video_notes do |t|
			t.integer :lecture_id
			t.integer :user_id

			t.text    :data
			t.integer  :time
    
			t.timestamps
		end

		add_index :video_notes, [ :lecture_id ,:updated_at ]
		add_index :video_notes, :lecture_id
		add_index :video_notes, :user_id
		add_index :video_notes, :updated_at
	end

	def down
		drop_table :video_notes
	end    

end

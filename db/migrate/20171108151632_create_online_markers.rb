class CreateOnlineMarkers < ActiveRecord::Migration[5.1]
	def up
		create_table :online_markers do |t|
			t.integer :lecture_id
			t.integer :group_id
			t.integer :course_id

			t.float   :time
			t.text 	  :annotation
			t.text    :title
			t.boolean :hide,    :default => false

			t.timestamps
		end

		add_index :online_markers, [ :course_id ,:updated_at ]
		add_index :online_markers, :course_id
		add_index :online_markers, :group_id
		add_index :online_markers, :lecture_id
		add_index :online_markers, :updated_at 
	end

	def down
		drop_table :online_markers
	end    
end
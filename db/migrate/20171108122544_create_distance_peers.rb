class CreateDistancePeers < ActiveRecord::Migration[5.1]
	def up
		create_table :distance_peers do |t|
			t.integer  :course_id
			t.integer  :group_id
			t.integer  :lecture_id
			t.integer  :user_id

			t.timestamps
		end
		add_index :distance_peers, :course_id
		add_index :distance_peers, :group_id
		add_index :distance_peers, :lecture_id 
		add_index :distance_peers, :user_id
	end

	def down
		drop_table :distance_peers		
	end

end

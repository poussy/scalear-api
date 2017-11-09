class CreateUserDistancePeers < ActiveRecord::Migration[5.1]
	def up
		create_table :user_distance_peers do |t|
			t.integer :user_id
			t.integer :online_quiz_id
			t.integer :distance_peer_id
			t.integer :status
			t.boolean :online,    :default => false

			t.timestamps
		end

		add_index :user_distance_peers, :online_quiz_id
		add_index :user_distance_peers, :user_id
		add_index :user_distance_peers, :distance_peer_id 
	end

	def down
		drop_table :user_distance_peers
	end  
end
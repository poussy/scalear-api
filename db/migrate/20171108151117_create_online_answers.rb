class CreateOnlineAnswers < ActiveRecord::Migration[5.1]
	def up
		create_table :online_answers do |t|
			t.integer :online_quiz_id
			t.text    :answer,         :default => ""
			t.float   :xcoor
			t.float   :ycoor
			t.boolean :correct
			t.text    :explanation,    :default => ""
			t.float   :width
			t.float   :height
			t.integer :pos
			t.float   :sub_ycoor
			t.float   :sub_xcoor

			t.timestamps
		end

		add_index :online_answers, :online_quiz_id
	end

	def down
		drop_table :online_answers		
	end  
end
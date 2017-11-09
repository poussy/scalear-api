class CreateFreeAnswers < ActiveRecord::Migration[5.1]
	def up
		create_table :free_answers do |t|
			t.integer :user_id
			t.integer :quiz_id
			t.integer :question_id
			t.text    :answer
			t.text    :response,     :default => ""
			t.boolean :hide,         :default => true
			t.integer :grade
			t.boolean :student_hide, :default => false

			t.timestamps
		end
		add_index :free_answers, :user_id
		add_index :free_answers, :quiz_id 
		add_index :free_answers, :question_id
	end

	def down
		drop_table :free_answers		
	end  
end

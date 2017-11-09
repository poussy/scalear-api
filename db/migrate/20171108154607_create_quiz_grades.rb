class CreateQuizGrades < ActiveRecord::Migration[5.1]
	def up
		create_table :quiz_grades do |t|
			t.integer :user_id
			t.integer :quiz_id
			t.integer :question_id
			t.integer :answer_id
			t.float   :grade

			t.timestamps
		end

		add_index :quiz_grades, [:quiz_id, :updated_at] 
		add_index :quiz_grades, :user_id
		add_index :quiz_grades, :quiz_id
		add_index :quiz_grades, :question_id
		add_index :quiz_grades, :answer_id
		add_index :quiz_grades, :updated_at 
	end

	def down
		drop_table :quiz_grades
	end  

end

class CreateOnlineQuizGrades < ActiveRecord::Migration[5.1]
	def up
		create_table :online_quiz_grades do |t|
			t.integer :lecture_id
			t.integer :group_id
			t.integer :course_id
			t.integer :user_id
			t.integer :online_quiz_id
			t.integer :online_answer_id
			t.float   :grade
			t.text 	  :optional_text
			t.boolean :review_vote,    :default => false
			t.boolean :in_group,    :default => false
			t.boolean :inclass,    :default => false
			t.boolean :distance_peer,    :default => false
			t.integer :attempt

			t.timestamps
		end

		add_index :online_quiz_grades, [ :course_id ,:updated_at ]
		add_index :online_quiz_grades, :course_id
		add_index :online_quiz_grades, :group_id
		add_index :online_quiz_grades, :lecture_id
		add_index :online_quiz_grades, :updated_at 
		add_index :online_quiz_grades, :user_id
		add_index :online_quiz_grades, :online_quiz_id
		add_index :online_quiz_grades, :online_answer_id

	end

	def down
		drop_table :online_quiz_grades
	end    
end

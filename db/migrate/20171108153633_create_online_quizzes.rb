class CreateOnlineQuizzes < ActiveRecord::Migration[5.1]
	def up
		create_table :online_quizzes do |t|
			t.integer :lecture_id
			t.text     :question
			t.float    :time
			t.boolean  :hide,          :default => true
			t.string   :question_type, :default => "OCQ"
			t.string   :quiz_type,     :default => "invideo"
			t.integer  :group_id
			t.integer  :course_id
			t.float    :start_time
			t.float    :end_time
			t.boolean  :inclass,       :default => false
			t.boolean  :graded,        :default => true
			t.boolean  :display_text,  :default => false
			t.integer  :intro,         :default => 120
			t.integer  :self,          :default => 120
			t.integer  :in_group,      :default => 120
			t.integer  :discussion,    :default => 120

			t.timestamps
		end

		add_index :online_quizzes, :lecture_id
		add_index :online_quizzes, :updated_at 
	end

	def down
		drop_table :online_quizzes
	end  
end
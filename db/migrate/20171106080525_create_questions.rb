class CreateQuestions < ActiveRecord::Migration[5.1]
  def change
    create_table :questions do |t|
      t.integer  :quiz_id
      t.text     :content
      t.datetime :created_at,                       :null => false
      t.datetime :updated_at,                       :null => false
      t.string   :question_type
      t.boolean  :show,          :default => false
      t.integer  :position
      t.boolean  :student_show,  :default => true
    end
    add_index :questions, [:quiz_id], :name => "index_questions_on_quiz_id"
  end
end

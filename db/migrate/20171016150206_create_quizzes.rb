class CreateQuizzes < ActiveRecord::Migration[5.1]
  def up
    create_table :quizzes do |t|
      t.string   :name
      t.integer  :retries

      t.integer  :group_id
      t.integer  :course_id

      t.boolean  :appearance_time_module, :default => true
      t.datetime :appearance_time
      t.boolean  :due_date_module,        :default => true
      t.datetime :due_date

      t.integer  :position
      t.boolean  :required,               :default => true
      t.boolean  :graded,                 :default => true

      t.boolean  :required_module,        :default => true
      t.boolean  :graded_module,          :default => true

      t.boolean  :visible,                :default => false
      t.string   :quiz_type

      t.text     :instructions

      t.timestamps
    end

    add_index :quizzes, :course_id
    add_index :quizzes, :group_id
    add_index :quizzes, :updated_at 
    add_index :quizzes, [ :course_id, :updated_at]
  end

  def down
    drop_table :quizzes
  end
end

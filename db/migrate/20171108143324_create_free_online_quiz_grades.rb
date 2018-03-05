class CreateFreeOnlineQuizGrades < ActiveRecord::Migration[5.1]
  def up
    create_table :free_online_quiz_grades do |t|
      t.integer :user_id
      t.integer :online_quiz_id
      t.text    :online_answer
      t.float   :grade
      t.integer :lecture_id
      t.integer :group_id
      t.integer :course_id
      t.text    :response,       :default => ""
      t.boolean :hide,           :default => true
      t.boolean :review_vote,    :default => false
      t.integer :attempt

      t.timestamps
    end

    add_index :free_online_quiz_grades, [ :course_id ,:updated_at ]
    add_index :free_online_quiz_grades, :course_id
    add_index :free_online_quiz_grades, :group_id
    add_index :free_online_quiz_grades, :lecture_id
    add_index :free_online_quiz_grades, :online_quiz_id
    add_index :free_online_quiz_grades, :user_id
    add_index :free_online_quiz_grades, :updated_at 
  end

  def down
    drop_table :free_online_quiz_grades
  end
end
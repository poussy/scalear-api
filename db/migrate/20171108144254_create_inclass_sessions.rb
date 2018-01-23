class CreateInclassSessions < ActiveRecord::Migration[5.1]
  def up
    create_table :inclass_sessions do |t|
      t.integer :online_quiz_id
      t.integer :lecture_id
      t.integer :group_id
      t.integer :course_id
      t.integer :status

      t.timestamps
    end

    add_index :inclass_sessions, :course_id
    add_index :inclass_sessions, :group_id
    add_index :inclass_sessions, :lecture_id
    add_index :inclass_sessions, :online_quiz_id
  end

  def down
    drop_table :inclass_sessions
  end

end
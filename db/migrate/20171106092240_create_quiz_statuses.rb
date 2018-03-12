class CreateQuizStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :quiz_statuses do |t|
      t.integer    :user_id
      t.integer    :quiz_id
      t.integer    :course_id
      t.string     :status
      t.integer    :attempts,   :default => 0
      t.integer    :group_id

      t.timestamps
    end
    add_index :quiz_statuses, :course_id
    add_index :quiz_statuses, :quiz_id
    add_index :quiz_statuses, :user_id
  end
end

class CreateAssignmentStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :assignment_statuses do |t|
      t.integer   :user_id
      t.integer   :course_id
      t.integer   :group_id
      t.integer   :status
      t.timestamps
    end
  end
end

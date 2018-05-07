class UpdateQuizStatusesAttempts < ActiveRecord::Migration[5.1]
  def change
    change_column_default :quiz_statuses, :attempts, 1
  end
end

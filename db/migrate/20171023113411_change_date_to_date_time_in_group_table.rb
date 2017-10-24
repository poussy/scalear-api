class ChangeDateToDateTimeInGroupTable < ActiveRecord::Migration[5.1]
  def up
    change_column :groups, :appearance_time, :datetime
    change_column :groups, :due_date, :datetime
  end

  def down
    change_column :groups, :appearance_time, :date
    change_column :groups, :due_date, :date
  end
end

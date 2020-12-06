class CreateExportLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :export_logs do |t|
      t.integer :course_id
      t.string :status

      t.timestamps
    end
  end
end

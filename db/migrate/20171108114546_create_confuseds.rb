class CreateConfuseds < ActiveRecord::Migration[5.1]
  def up
    create_table :confuseds do |t|
      t.integer  :user_id
      t.integer  :course_id
      t.integer  :lecture_id
      t.float    :time
      t.boolean  :very,       :default => false
      t.boolean  :hide,       :default => true

      t.timestamps
    end
    add_index :confuseds, [ :course_id, :updated_at]
    add_index :confuseds, :course_id
    add_index :confuseds, :lecture_id
    add_index :confuseds, :updated_at
    add_index :confuseds, :user_id
  end

  def down
    drop_table :confuseds
  end
end

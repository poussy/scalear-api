class CreateAnnouncements < ActiveRecord::Migration[5.1]
  def up
    create_table :announcements do |t|
		t.string   :announcement
		t.integer  :course_id
		t.integer  :user_id
		t.datetime   :date
      t.timestamps
    end
    add_index :announcements, :course_id
    add_index :announcements, :user_id
    add_index :announcements, :updated_at 
    add_index :announcements, [ :course_id, :updated_at]    
  end

  def down
  	drop_table :announcements
  end
end

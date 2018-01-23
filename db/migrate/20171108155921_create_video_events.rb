class CreateVideoEvents < ActiveRecord::Migration[5.1]
  def up
    create_table :video_events do |t|
      t.integer  :course_id
      t.integer  :group_id
      t.integer  :lecture_id
      t.integer  :user_id
      t.integer  :event_type
      t.float    :from_time
      t.float    :to_time
      t.boolean  :in_quiz
      t.float    :speed
      t.float    :volume
      t.boolean  :fullscreen
    
      t.timestamps
    end

    add_index :video_events, :course_id
    add_index :video_events, :group_id
    add_index :video_events, :lecture_id
    add_index :video_events, :event_type
    add_index :video_events, :user_id
  end

  def down
    drop_table :video_events
  end    
end

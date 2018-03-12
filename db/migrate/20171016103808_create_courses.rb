class CreateCourses < ActiveRecord::Migration[5.1]
  def up
    create_table :courses do |t|
      t.integer  :user_id
      t.string   :short_name
      t.string   :name
      t.string   :time_zone
      
      t.date     :start_date
      t.date     :end_date
      t.date     :disable_registration

      t.text     :description
      t.text     :prerequisites

      t.string   :discussion_link,  :default => ""
      t.string   :image_url
      
      t.string   :unique_identifier
      t.string   :guest_unique_identifier
      
      t.boolean  :importing,        :default => false

    t.timestamps
    end

    add_index :courses, :user_id
    add_index :courses, :unique_identifier, :unique => true
    add_index :courses, :guest_unique_identifier, :unique => true

  end

  def down
    drop_table :courses
  end
end

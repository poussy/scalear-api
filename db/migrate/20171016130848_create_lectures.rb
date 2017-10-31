class CreateLectures < ActiveRecord::Migration[5.1]
  def up
    create_table :lectures do |t|
		t.string   :name
		
		t.float    :start_time
		t.float    :end_time
		t.float    :duration

		t.integer  :group_id
		t.integer  :course_id

		t.boolean  :appearance_time_module, :default => true
		t.datetime  :appearance_time
		t.boolean  :due_date_module, :default => true
		t.datetime  :due_date

		t.string   :slides
		t.integer  :position
		t.string   :aspect_ratio, :default => "widescreen"
		t.boolean  :required, :default => true
		t.boolean  :graded, :default => true

		t.boolean  :required_module, :default => true
		t.boolean  :graded_module, :default => true

		t.boolean   :inclass, :default => false
		t.boolean   :distance_peer, :default => false
		t.text     :description

		t.string   :url

      t.timestamps
      	t.integer  :parent_id
    end
    add_index :lectures, :course_id
    add_index :lectures, :group_id
    add_index :lectures, :updated_at 
    add_index :lectures, [ :course_id, :updated_at]

    add_column :courses, :parent_id, :integer
    add_column :groups, :parent_id, :integer
  end

  def down
  	drop_table :lectures
  end
end

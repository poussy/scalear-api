class CreateGroups < ActiveRecord::Migration[5.1]
  def up
    create_table :groups do |t|
	    t.string   :name
	    t.integer  :course_id
	    t.datetime :appearance_time
	    t.datetime :due_date
	    t.boolean  :inorder
	    t.boolean  :required
	    t.integer :position
	    t.text     :description
	    
		t.timestamps
    end
    add_index :groups, :course_id
    add_index :groups, :updated_at
    add_index :groups, [:course_id , :updated_at]
  end

  def down
  	drop_table :groups
  end
end

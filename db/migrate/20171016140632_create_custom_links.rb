class CreateCustomLinks < ActiveRecord::Migration[5.1]
  def up
    create_table :custom_links do |t|
      t.string   :name
      t.integer  :group_id
      t.integer  :course_id
      t.integer  :position
      t.string   :url
      t.timestamps
    end
    add_index :custom_links, :course_id
    add_index :custom_links, :group_id
    add_index :custom_links, :updated_at 
    add_index :custom_links, [ :course_id, :updated_at]    
  end

  def down
    drop_table :custom_links
  end
end

class CreateSharedItems < ActiveRecord::Migration[5.1]
  def up
    create_table :shared_items do |t|
      t.text :data
      t.references :shared_by
      t.references :shared_with
      t.boolean  :accept

      t.timestamps
    end
  end

  def down
    drop_table :shared_items    
  end
end

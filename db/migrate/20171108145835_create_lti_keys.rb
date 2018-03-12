class CreateLtiKeys < ActiveRecord::Migration[5.1]
  def up
    create_table :lti_keys do |t|
      t.integer :user_id
      t.integer :organization_id
      t.string :consumer_key
      t.string :shared_sceret

      t.timestamps
    end

    add_index :lti_keys, :shared_sceret
    add_index :lti_keys, :consumer_key
    add_index :lti_keys, :organization_id
    add_index :lti_keys, :user_id
  end

  def down
    drop_table :lti_keys
  end
end
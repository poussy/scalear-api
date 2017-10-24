class AddNeededColumnsToUsers < ActiveRecord::Migration[5.1]
  def change
      add_column :users, :last_name, :string
      add_column :users, :screen_name, :string
      add_column :users, :university, :string
      add_column :users, :link, :string
      add_column :users, :bio, :string
      add_column :users, :discussion_pref, :integer, :default => 1
      add_column :users, :completion_wizard, :text
      add_column :users, :first_day, :integer, :default => 0
      add_column :users, :canvas_id, :integer
      add_column :users,  :canvas_last_signin, :datetime
  end
end

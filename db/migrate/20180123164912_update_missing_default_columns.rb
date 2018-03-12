class UpdateMissingDefaultColumns < ActiveRecord::Migration[5.1]
  def change
  	change_column :lectures, :appearance_time_module, :boolean, default: true
  	change_column :lectures, :due_date_module, :boolean, default: true

  	change_column :quizzes, :appearance_time_module, :boolean, default: true
  	change_column :quizzes, :due_date_module, :boolean, default: true
  	
  	change_column :user_distance_peers, :online, :boolean, default: false
  end
end

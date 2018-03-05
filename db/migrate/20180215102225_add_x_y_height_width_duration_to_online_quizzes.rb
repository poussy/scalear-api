class AddXYHeightWidthDurationToOnlineQuizzes < ActiveRecord::Migration[5.1]
  def change
    add_column :online_quizzes, :xcoor, :float, :default => 0.0 
    add_column :online_quizzes, :ycoor, :float, :default => 0.9 
    add_column :online_quizzes, :height, :float, :default => 0.1 
    add_column :online_quizzes, :width, :float, :default => 0.5 
  end
end

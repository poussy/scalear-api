class AddXYHeightWidthDurationToOnlineMarkers < ActiveRecord::Migration[5.1]
  def change
    add_column :online_markers, :xcoor, :float, :default => 0.0 
    add_column :online_markers, :ycoor, :float, :default => 0.9 
    add_column :online_markers, :height, :float, :default => 0.1 
    add_column :online_markers, :width, :float, :default => 0.5 
    add_column :online_markers, :duration, :integer, :default => 5 
  end
end

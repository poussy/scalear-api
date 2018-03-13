class AddAsSlideToOnlineMarkers < ActiveRecord::Migration[5.1]
  def change
    add_column :online_markers, :as_slide, :boolean, :default => false
  end
end

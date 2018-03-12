class AddSkipAheadAndSkipAheadModuleToLectures < ActiveRecord::Migration[5.1]
  def change
    add_column :lectures, :skip_ahead,        :boolean, :default => true
    add_column :lectures, :skip_ahead_module, :boolean, :default => true
  end
end

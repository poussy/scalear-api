class ChangeUrlLectureTypeToText < ActiveRecord::Migration[5.1]
  def up
    change_column :lectures, :url, :text
  end
end

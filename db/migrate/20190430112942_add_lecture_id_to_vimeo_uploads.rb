class AddLectureIdToVimeoUploads < ActiveRecord::Migration[5.1]
  def change
    add_column :vimeo_uploads, :lecture_id, :integer
  end
end

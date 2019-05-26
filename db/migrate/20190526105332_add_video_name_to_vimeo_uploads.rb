class AddVideoNameToVimeoUploads < ActiveRecord::Migration[5.1]
  def change
    add_column :vimeo_uploads, :video_name, :string
  end
end

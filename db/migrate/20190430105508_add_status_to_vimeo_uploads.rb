class AddStatusToVimeoUploads < ActiveRecord::Migration[5.1]
  def change
    add_column :vimeo_uploads, :status, :string
  end
end

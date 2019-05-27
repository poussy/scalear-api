class CreateVimeoUploads < ActiveRecord::Migration[5.1]
  def change
    create_table :vimeo_uploads do |t|
      t.integer :user_id
      t.string :vimeo_url

      t.timestamps
    end
  end
end

class CreateYtDataApiReqLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :yt_data_api_req_logs do |t|
      t.string :cause
      t.integer :user_id
      t.integer :lecture_id
      t.timestamps
    end
  end
end

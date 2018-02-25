class AddEncryptedEmailAndEncryptedDataToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :encrypted_email, :string
    add_column :users, :encrypted_data, :json
  end
end

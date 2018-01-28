class AddSamlToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :saml, :boolean, :default => false
  end
end

class CreateUsers < ActiveRecord::Migration[5.1]
  def up
    create_table :users do |t|
      # ## Database authenticatable
      t.string :encrypted_password, :default => "", :null => false

      # ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      # ## Rememberable
      t.datetime :remember_created_at

      # ## Trackable
      t.integer  :sign_in_count,    :default => 0,  :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      # ## Lockable
      t.integer  :failed_attempts,  :default => 0,  :null => false  # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      # ## User Info
      t.string   :last_name
      t.string   :screen_name
      t.string   :university
      t.string   :link
      t.string   :bio
      t.string   :completion_wizard
      t.integer  :first_day,        :default => 0
      t.integer  :canvas_id
      t.datetime :canvas_last_signin
      t.string   :email
      t.string   :name
      t.integer  :discussion_pref,  :default => 1
      t.boolean  :saml,             :default => false

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
  end
end

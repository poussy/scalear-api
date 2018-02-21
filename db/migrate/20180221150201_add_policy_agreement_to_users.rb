class AddPolicyAgreementToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :policy_agreement, :json
  end
end

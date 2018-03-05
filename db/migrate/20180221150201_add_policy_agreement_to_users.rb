class AddPolicyAgreementToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :policy_agreement, :json

    ActiveRecord::Base.transaction do
      User.where(policy_agreement:nil).each do |user|
        user.update_attribute('policy_agreement',{'date' => user.created_at, 'ip' => '0.0.0.0'})
      end
    end
  end
end

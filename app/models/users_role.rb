class UsersRole < ApplicationRecord
  attr_accessible :user_id, :role_id , :admin_school_domain
  belongs_to :user
  belongs_to :role
end

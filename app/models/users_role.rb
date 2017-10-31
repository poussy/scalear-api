class UsersRole < ApplicationRecord
	
	validates_uniqueness_of :user_id,  :scope => :role_id #the pair course_id user_id must be unique
	belongs_to :user
	belongs_to :role
end

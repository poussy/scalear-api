class Role < ApplicationRecord
	has_and_belongs_to_many :users, :join_table => :users_roles
	has_many :teacher_enrollments

	def display_name
		name
	end

end

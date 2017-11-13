class Enrollment < ApplicationRecord
	belongs_to :course, :touch => true
	belongs_to :user, :touch => true #so when enrollments change, it affect the associated user. (updated_at column)	
	validates_uniqueness_of :user_id,  :scope => :course_id #the pair course_id user_id must be unique

	before_destroy :delete_student_data

	def delete_student_data
		user.delete_student_data(course_id)
	end
end
class GuestEnrollment < ApplicationRecord
	belongs_to :course, :touch => true
	belongs_to :user, :touch => true

	validates_uniqueness_of :user_id,  :scope => :course_id #the pair course_id user_id must be unique	

	# private
	# 	def delete_student_data
	# 	end

end

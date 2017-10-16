class Enrollment < ApplicationRecord
	attr_accessible :course_id, :user_id , :email_due_date	
	belongs_to :course, :touch => true
	belongs_to :user, :touch => true #so when enrollments change, it affect the associated user. (updated_at column)	

end

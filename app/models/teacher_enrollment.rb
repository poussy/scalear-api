class TeacherEnrollment < ApplicationRecord
  attr_accessible :course_id, :user_id, :role_id, :email_discussion 
  validates_uniqueness_of :user_id,  :scope => :course_id #the pair course_id user_id must be unique
  
  belongs_to :course, :touch => true
  belongs_to :user, :touch => true
end

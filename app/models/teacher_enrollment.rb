class TeacherEnrollment < ApplicationRecord
  validates_uniqueness_of :user_id,  :scope => :course_id #the pair course_id user_id must be unique
  
  belongs_to :course, :touch => true
  belongs_to :user, :touch => true
end

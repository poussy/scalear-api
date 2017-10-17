class GuestEnrollment < ApplicationRecord
  belongs_to :course, :touch => true
  belongs_to :user, :touch => true

  attr_accessible :course_id, :user_id

  # user y can be enrolled in course x once only
  validates_uniqueness_of :user_id,  :scope => :course_id #the pair course_id user_id must be unique	
end

class LectureView < ApplicationRecord
	belongs_to :lecture
	belongs_to :group
	belongs_to :course
	belongs_to :user

	validates :course_id, :lecture_id, :user_id, :presence => true  #:percent
end
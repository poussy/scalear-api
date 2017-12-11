class AssignmentItemStatus < ApplicationRecord
	belongs_to :quiz, optional: true
	belongs_to :course
	belongs_to :group
	belongs_to :lecture, optional: true
	belongs_to :user

	validates :course_id, :group_id, :user_id, :presence => true #can't have group_id because it is added after saving the group! so validation fails.
end
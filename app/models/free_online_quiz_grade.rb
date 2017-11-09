class FreeOnlineQuizGrade < ApplicationRecord

	belongs_to :user
	belongs_to :lecture
	belongs_to :group
	belongs_to :course
	belongs_to :online_quiz

	serialize :online_answer, Object

end
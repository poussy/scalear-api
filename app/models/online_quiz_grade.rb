class OnlineQuizGrade < ApplicationRecord

	belongs_to :lecture
	belongs_to :online_answer
	belongs_to :online_quiz
	belongs_to :group
	belongs_to :user
	belongs_to :course

	validates :online_answer_id, :online_quiz_id, :user_id, :lecture_id, :presence => true
end
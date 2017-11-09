class QuizGrade < ApplicationRecord
	validates :question_id, :answer_id, :quiz_id, :user_id, :presence => true

	belongs_to :answer
	belongs_to :user
	belongs_to :quiz
	belongs_to :question
end
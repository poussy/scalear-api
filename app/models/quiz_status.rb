class QuizStatus < ApplicationRecord

	validates :attempts, :numericality => {:only_integer => true}

	belongs_to :user
	belongs_to :quiz
	belongs_to :group
	belongs_to :course

end

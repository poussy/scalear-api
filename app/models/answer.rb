class Answer < ApplicationRecord
	belongs_to :question
	has_many :quiz_grades

	# before_destroy :delete_quiz_grades

	serialize :content, Object
	serialize :explanation, Object

	private
	# 	def delete_quiz_grades
	# 	end    
end
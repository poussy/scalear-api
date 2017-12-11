class Question < ApplicationRecord

	belongs_to :quiz
	
	has_many :answers, -> { order :id }
	has_many :free_answers, :dependent => :destroy
	has_many :quiz_grades

	validates :content,:quiz_id,:question_type, :presence => true   #:content

	attribute :match_type


	# before_destroy :delete_user_data

	private
	# 	def delete_user_data
	# 	end
end

class OnlineQuiz < ApplicationRecord
	
	has_many :online_answers, -> { order('id') }, :dependent => :destroy
	has_many :online_quiz_grades , :dependent => :destroy
	has_many :free_online_quiz_grades , :dependent => :destroy
	has_many :user_distance_peers, :dependent => :destroy

	has_one :inclass_session, :dependent => :destroy
	belongs_to :lecture, :touch => true
	belongs_to :group
	belongs_to :course

	validates :time,:start_time, :end_time,:lecture_id,:question,  :intro, :self, :in_group, :discussion, :presence => true


	# def formatted_time
	# end

	# def is_quiz_solved
	# end

	# def get_votes
	# end

	# def get_chart(students_id)
	# end
end
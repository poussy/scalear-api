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

	attribute :match_type
	attribute :solved_quiz
	attribute :reviewed
	attribute :votes_count
	attribute :online_answers
	attribute :online_answers_drag

	# def formatted_time
	# end

	# def is_quiz_solved
	# end

	def get_votes
		if self.question_type.upcase=="DRAG" || self.question_type.upcase=="FREE TEXT QUESTION"
			return self.free_online_quiz_grades.where(:attempt=>1).select{|grade| grade.review_vote }.map{|a| a.user_id}.uniq.count
		else
			return self.online_quiz_grades.where(:attempt=>1).select{|grade| grade.review_vote}.map{|a| a.user_id}.uniq.count
		end		
	end

	# def get_chart(students_id)
	# end
end
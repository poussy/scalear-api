class InclassSession < ApplicationRecord
#########################
# status 0 => not running
# status 1 => start
# status 2 => self
# status 3 => group
# status 4 => discussion
# status 5 => end
#########################
	belongs_to :lecture, :touch => true
	belongs_to :group
	belongs_to :course
	belongs_to :online_quiz
	
	validates :status, :online_quiz_id, :presence => true
	validates :online_quiz_id, :presence => true, :uniqueness => true
	
end
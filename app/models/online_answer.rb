class OnlineAnswer < ApplicationRecord

	validates :xcoor, :ycoor,:online_quiz_id, :presence => true
	# validates :answer, :presence => true, :unless => :skip_validation?

	# before_destroy :delete_all_data

	belongs_to :online_quiz
	serialize :explanation, Object
	serialize :answer, Object

	has_many :online_quiz_grades

	# def skip_validation?
	# end

	private
		# def delete_all_data
		# end
end
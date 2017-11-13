class Event < ApplicationRecord
	# has_event_calendar
	belongs_to :quiz, optional: true
	belongs_to :course
	belongs_to :group, optional: true
	belongs_to :lecture, optional: true


	validates :course_id, :name, :presence => true #can't have group_id because it is added after saving the group! so validation fails.

	# after_validation :message

	# def message
	# end

	# def self.appeared?(course)
	# end

	# def get_color(current_user)
	# end
end
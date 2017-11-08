class VideoEvent < ApplicationRecord
	############
	# Play => 1
	# Pause => 2
	# Seek => 3
	# Fullscreen => 4
	##################

	belongs_to :user
	belongs_to :lecture
	belongs_to :course
	belongs_to :group

	# def self.get_events
	# end

	# def self.get_event(event)
	# end
end
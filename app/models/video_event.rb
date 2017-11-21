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

	def self.get_rounded_time_module(array)
		return_hash={}
		Time.zone="UTC"
		array.each do |k,v|
			parsed_time=Time.zone.parse(Time.seconds_to_time(k[1])).floor(15.seconds).to_i #currently rounding to nearest minute. could change that. #to_i to use it in javascript
			return_hash[(parsed_time+k[0]).to_i] = (return_hash[(parsed_time+k[0]).to_i]||0) + 1
		end
		return return_hash.to_a    
  	end
end

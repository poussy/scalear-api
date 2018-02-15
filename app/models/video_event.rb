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

	def self.get_events
    	{:play => 1, :pause => 2, :seek => 3, :fullscreen => 4}
  	end

	def self.get_event(event)
		get_events[event.to_sym]
	end


	def self.get_rounded_time_module(array)
		return_hash={}
		Time.zone="UTC"
		array.each do |k,v|
			parsed_time=Time.zone.parse(Time.seconds_to_time(k[1])).floor(15.seconds).to_i #currently rounding to nearest minute. could change that. #to_i to use it in javascript
			return_hash[(parsed_time+k[0]).to_i] = (return_hash[(parsed_time+k[0]).to_i]||0) + 1
		end
		return return_hash.to_a    
  	end

	def self.get_questions_rounded_time_module(array)
		return_hash={}
		questions={}
		Time.zone="UTC"
		array.each do |k,v|
			parsed_time=Time.zone.parse(Time.seconds_to_time(k[1])).floor(15.seconds).to_i #currently rounding to nearest minute. could change that. #to_i to use it in javascript
			return_hash[(parsed_time+k[0]).to_i] = (return_hash[(parsed_time+k[0]).to_i]||0) + 1
			if questions[(parsed_time+k[0]).to_i]
			questions[(parsed_time+k[0]).to_i] << v[1]
			else
			questions[(parsed_time+k[0]).to_i] = [v[1]]
			end
		end
		return_hash.merge!(questions){|k,v1,v2| [v1,v2]}
		return return_hash
  	end
end

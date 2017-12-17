	class Confused < ApplicationRecord
	belongs_to :lecture
	belongs_to :user
	belongs_to :course

	# def self.get_rounded_time_check(array)
	# end

	# def self.get_rounded_time(array)
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

	def self.get_rounded_time_lecture(array)
		return_hash={}
		array.each do |v|
			parsed_time=v.time % 15 == 0 ? v.time : v.time - (v.time % 15)
			return_hash[parsed_time] = {:count =>0, :show => false} if return_hash[parsed_time].nil?
			return_hash[parsed_time][:count] += 1
			return_hash[parsed_time][:show] = !v.hide if !v.hide
		end
		return return_hash.to_a
	end

end
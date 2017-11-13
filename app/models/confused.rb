class Confused < ApplicationRecord
	belongs_to :lecture
	belongs_to :user
	belongs_to :course

	# def self.get_rounded_time_check(array)
	# end

	# def self.get_rounded_time(array)
	# end

	# def self.get_rounded_time_module(array)
	# end

	# def self.get_rounded_time_lecture(array)
	# end

end
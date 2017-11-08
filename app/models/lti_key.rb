class LtiKey < ApplicationRecord
	belongs_to :user , optional: true
	belongs_to :organization, optional: true
	validates_uniqueness_of :user_id
	validates_uniqueness_of :organization_id
	
	# validate :user_xor_organization
	# before_create :create_consumer_key
	# before_create :create_shared_sceret  

	# def create_consumer_key
	# end

	# def generate_random_consumer_key
	# end

	# def create_shared_sceret
	# end

	# def generate_random_shared_sceret
	# end

	# private
	# 	def user_xor_organization
	# 	end
end
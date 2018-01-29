class LtiKey < ApplicationRecord
	belongs_to :user , optional: true
	belongs_to :organization, optional: true
	validates_uniqueness_of :user_id
	validates_uniqueness_of :organization_id	

	validate :user_xor_organization
	before_create :create_consumer_key
	before_create :create_shared_sceret  

	def create_consumer_key
		begin
			self.consumer_key = generate_random_consumer_key
		end while self.class.exists?(:consumer_key => consumer_key)		
	end

	def generate_random_consumer_key
		(0...30).map { [*('A'..'H'),*('J'..'N'), *('P'..'Z'),*('0'..'9')].to_a[rand(34)] }.join 
	end

	def create_shared_sceret
		begin
			self.shared_sceret = generate_random_shared_sceret
		end while self.class.exists?(:shared_sceret => shared_sceret)
	end

	def generate_random_shared_sceret
		(0...30).map { [*('A'..'H'),*('J'..'N'), *('P'..'Z'),*('0'..'9')].to_a[rand(34)] }.join 
	end

	private
		def user_xor_organization
			unless user_id.blank? ^ organization_id.blank?
				errors.add(:user, "Specify a user or a organization, not both")
			end			
		end
end
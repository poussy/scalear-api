class Organization < ApplicationRecord
	
	validates :name, :domain , presence: true 
	validates :domain, uniqueness: true 
	has_one :lti_key, :dependent => :destroy 
	has_and_belongs_to_many :users, :join_table => :users_roles
end
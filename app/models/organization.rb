class Organization < ApplicationRecord
	validates :name, :domain , presence: true

	has_one :lti_key, :dependent => :destroy
end
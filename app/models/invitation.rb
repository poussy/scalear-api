class Invitation < ApplicationRecord
	validates_uniqueness_of :email,  :scope => :course_id, :message => :already_invited
	validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

	belongs_to :course
	belongs_to :user
	belongs_to :role
end
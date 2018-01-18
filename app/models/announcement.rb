class Announcement < ApplicationRecord
	belongs_to :user
	belongs_to :course

	validates :announcement, :date, :presence => true

	attribute :course_name
end
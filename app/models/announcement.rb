class Announcement < ApplicationRecord
	attr_accessible :announcement, :course_id, :date, :user_id
	belongs_to :user
	belongs_to :course
end

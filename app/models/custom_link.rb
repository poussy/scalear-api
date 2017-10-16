class CustomLink < ApplicationRecord
	attr_accessible :course_id, :group_id, :name, :url, :position, :course_position
	belongs_to :group
	belongs_to :course
end

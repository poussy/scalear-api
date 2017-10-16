class Group < ApplicationRecord
	attr_accessible :course_id, :description, :name, :appearance_time, :position, :due_date, :inorder ,:required
	belongs_to :course, :touch => true
end

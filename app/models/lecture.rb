class Lecture < ApplicationRecord
	attr_accessible :course_id, :description, :name, :url, :group_id, :appearance_time, :due_date, :duration,:aspect_ratio, :slides, :appearance_time_module, :due_date_module,:required_module , :inordered_module, :position, :required, :inordered, :start_time, :end_time, :type 
	belongs_to :course, :touch => true
	belongs_to :group
end

class CustomLink < ApplicationRecord
	belongs_to :group
	belongs_to :course

	attribute :class_name
	
	validates :course_id,:name, :url, :presence => true
  
	# def get_class_name
	# end
end
class CustomLink < ApplicationRecord
	belongs_to :group
	belongs_to :course

	attribute :class_name
	
	# def get_class_name
	# end
end
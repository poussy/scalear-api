class CustomLink < ApplicationRecord
	belongs_to :group
	belongs_to :course

	attribute :class_name 

end

class Group < ApplicationRecord
	attr_accessible :course_id, :description, :name, :appearance_time, :position, :due_date, :inorder ,:required
	belongs_to :course, :touch => true
	has_many :lectures, :order => :position, :dependent => :destroy 
	has_many :custom_links, :dependent => :destroy
end

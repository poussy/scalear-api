class Group < ApplicationRecord
	belongs_to :course, :touch => true
	has_many :lectures, :order => :position, :dependent => :destroy 
	has_many :quizzes,:order => :position, :dependent => :destroy 
	has_many :custom_links, :dependent => :destroy
end

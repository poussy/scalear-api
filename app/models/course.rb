class Course < ApplicationRecord
	attr_accessible :description, :end_date, :name, :prerequisites, :short_name, :start_date, :user_ids, :user_id, :time_zone, :discussion_link, :importing, :image_url ,:disable_registration	
	belongs_to :user
	has_many :groups, :order => "position", :dependent => :destroy
	has_many :lectures, :dependent => :destroy
	has_many :quizzes,:order => :position, :dependent => :destroy 	
	has_many :custom_links, :dependent => :destroy
	has_many :announcements, :dependent => :destroy

end
class Course < ApplicationRecord
	attr_accessible :description, :end_date, :name, :prerequisites, :short_name, :start_date, :user_ids, :user_id, :time_zone, :discussion_link, :importing, :image_url ,:disable_registration	
	has_many :groups, :order => "position", :dependent => :destroy
end

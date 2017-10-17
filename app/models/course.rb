class Course < ApplicationRecord
	belongs_to :user
	has_many :groups, :order => "position", :dependent => :destroy
	has_many :lectures, :dependent => :destroy
	has_many :quizzes,:order => :position, :dependent => :destroy 	
	has_many :custom_links, :dependent => :destroy
	has_many :announcements, :dependent => :destroy
	
	has_many :enrollments, :dependent => :destroy
	has_many :users, :through => :enrollments, :uniq => true

	has_many :teacher_enrollments, :dependent => :destroy
	has_many :teachers, :source => :user, :through => :teacher_enrollments, :uniq => true

	has_many :guest_enrollments, :dependent => :destroy
	has_many :guests, :source => :user, :through => :guest_enrollments, :uniq => true
end
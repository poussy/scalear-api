class Course < ApplicationRecord
	belongs_to :user
	has_many :groups, -> { order('position') }, :dependent => :destroy
	has_many :lectures, -> { order('position') }, :dependent => :destroy
	has_many :quizzes, -> { order('position') }, :dependent => :destroy 	
	has_many :custom_links, -> { order('position') }, :dependent => :destroy
	has_many :announcements, :dependent => :destroy
	
	has_many :enrollments, :dependent => :destroy
	has_many :users, -> { distinct }, :through => :enrollments

	has_many :teacher_enrollments, :dependent => :destroy
	has_many :teachers, -> { distinct }, :source => :user, :through => :teacher_enrollments

	has_many :guest_enrollments, :dependent => :destroy
	has_many :guests, -> { distinct }, :source => :user, :through => :guest_enrollments
end
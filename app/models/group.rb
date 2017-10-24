class Group < ApplicationRecord
	belongs_to :course, :touch => true
	
	has_many :lectures, -> { order('position') }, :dependent => :destroy 
	has_many :quizzes, -> { order('position') }, :dependent => :destroy 
	has_many :custom_links, -> { order('position') }, :dependent => :destroy

	after_destroy :clean_up

	# accepts_nested_attributes_for :lectures, :allow_destroy => true
	# accepts_nested_attributes_for :quizzes, :allow_destroy => true
	validates :appearance_time, :course_id, :name, :due_date, :presence => true
	validates_inclusion_of :inorder , :required, :in => [true, false] #not in presence because boolean false considered not present.

	private
		def clean_up
			# self.events.where(:lecture_id => nil, :quiz_id => nil).destroy_all
			p "Events destroyed"
		end
end

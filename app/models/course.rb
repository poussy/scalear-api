class Course < ApplicationRecord
	# belongs_to :user
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

	validates :name, :end_date, :short_name,:start_date, :user_id, :time_zone, :presence => true

	before_create :create_unique_identifier
	before_create :create_guest_unique_identifier

	# validates :unique_identifier, :guest_unique_identifier, uniqueness: true
	validate :unique_identifier_guest_unique_identifier_not_changed

	validate :validate_end_date_disable_regis_after_start_date ,on: [:create, :update]
	validates_format_of :image_url, :with    => %r{\.(((g|G)(i|I)(f|F))|((j|J)(p|P)(e|E)?(g|G))|((p|P)(n|N)(g|G)))}i, :message => :must_be_image, :allow_blank => true


	accepts_nested_attributes_for :users, :allow_destroy => true
	accepts_nested_attributes_for :groups, :allow_destroy => true



	
	private 
		def validate_end_date_disable_regis_after_start_date
			if end_date && start_date && end_date < start_date
				errors.add(:end_date, "courses.errors.end_date_pass")
			end
			if disable_registration && disable_registration < start_date
				errors.add(:disable_registration, "courses.errors.end_date_pass")
			end
		end

		def unique_identifier_guest_unique_identifier_not_changed
			if unique_identifier_changed?  && self.persisted?
				errors.add(:unique_identifier, "courses.errors.unique_identifier_changed")
			end
			if guest_unique_identifier_changed? && self.persisted?
				errors.add(:guest_unique_identifier, "courses.errors.guest_unique_identifier_changed")
			end
		end

		def create_unique_identifier
			begin
				self.unique_identifier = generate_random_unique_identifier
			end while ( self.class.exists?(:unique_identifier => unique_identifier)  || (self.class.exists?(:guest_unique_identifier => unique_identifier)  ) )
	 	end

		def create_guest_unique_identifier
			begin
				self.guest_unique_identifier = generate_random_unique_identifier
			end while  ( self.class.exists?(:unique_identifier => guest_unique_identifier)  || (self.class.exists?(:guest_unique_identifier => guest_unique_identifier)  ) )
		end

		def generate_random_unique_identifier
		(0...5).map { [*('A'..'H'),*('J'..'N'), *('P'..'Z')].to_a[rand(24)] }.join + '-' + (0...5).map { (0..9).to_a[rand(10)] }.join
		end

end
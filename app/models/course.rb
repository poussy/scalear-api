class Course < ApplicationRecord
	belongs_to :user
	has_many :groups, -> { order('position') }, :dependent => :destroy
	has_many :lectures, -> { order('position') }
	has_many :quizzes, -> { order('position') }
	has_many :custom_links, -> { order('position') }
	has_many :announcements, :dependent => :destroy
	
	has_many :enrollments, :dependent => :destroy
	# has_many :users, :through => :enrollments
	has_many :users, :through => :enrollments, :source => :user

	has_many :teacher_enrollments, :dependent => :destroy
	has_many :teachers, :through => :teacher_enrollments, :source => :user  # to get this call user.subjects


	has_many :guest_enrollments, :dependent => :destroy
	has_many :guests, :source => :user, :through => :guest_enrollments

	has_many :course_domains, :dependent => :destroy

	validates :name, :end_date, :short_name,:start_date, :user_id, :time_zone, :presence => true

	before_create :create_unique_identifier
	before_create :create_guest_unique_identifier

	validate :unique_identifier_guest_unique_identifier_not_changed

	validate :validate_end_date_disable_regis_after_start_date ,on: [:create, :update]
	validates_format_of :image_url, :with    => %r{\.(((g|G)(i|I)(f|F))|((j|J)(p|P)(e|E)?(g|G))|((p|P)(n|N)(g|G)))}i, :message => :must_be_image, :allow_blank => true
	
	def correct_teacher(user)
		if !(self.teachers.include? user) && !user.has_role?('Administrator') && !(self.is_school_administrator(user))  
			return false
		end
		return true
	end

	def correct_student(user)
		if !(self.users.include? user) && !(self.guests.include? user) 
			return false
		end
		return true
	end

	def is_school_administrator(user)
		user_role = UsersRole.where(:user_id => user.id, :role_id => 9)[0]
		if user_role
			email = user_role.admin_school_domain || nil
		end
		return user.has_role?('School Administrator') && self.teachers.select{|t| t.email.split("@").last.include?(email) }.size>0
	end

	def add_professor(user , email_discussion)
		self.teacher_enrollments.create(:user_id => user.id, :role_id => 3 , :email_discussion => email_discussion)
	end

	def add_ta(user)
		self.teacher_enrollments.create(:user_id => user.id, :role_id => 4)
	end
	
	# def surveys
	# end

	# def normal_quizzes
	# end

	def ended
		self.end_date < DateTime.now
	end

	def duration
		( self.end_date - self.start_date ).numerator / 7
	end

	def is_teacher(user)
		self.teachers.where(:id => current.id).count>0
	end

	def is_student(user)
		self.users.include? user
	end

	def is_guest(user)
		self.guests.include? user
	end

	def get_role_user(user)
		# 1 teacher, 2 student, 3 prof, 4 TA, 5 Admin, 6 preview, 7 guest
		role = 0
		if self.correct_teacher(user) ## teacher && administrator && school_administrator
			role = 1 
		elsif self.is_student(user)
			role = 2 
		elsif  self.is_guest(user)
			role = 7
		end
		return role
	end

	# def export_course(current_user)
	# end

	# def export_student_csv(current_user)
	# end

	# def import_course(import_from)
	# end


	# def self.our(user)
	# end

	# def enrolled_students #returns scope (relation)
	# end

	# def not_enrolled_students #returns scope (relation)
	# end

	# def export_for_transfer
	# end

	# def export_modules_progress(current_user)
	# end

	# def self.school_admin_statistics_course_ids(raw_start_date, raw_end_date, domain = 'All', current_user)
	# end

	# def self.school_admin_statistics_course_data(raw_start_date, raw_end_date, active_courses_ids)
	# end

	# class << self
	# 	def export_school_data(start_date, end_date, domain, current_user)
	# 	end

	# 	def self.export_school_admin(start_date, end_date, domain, current_user)
	# 	end
	# end


	private 
		# def validate_end_date_after_start_date
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
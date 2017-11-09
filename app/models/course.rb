class Course < ApplicationRecord
	belongs_to :user
	has_many :groups, -> { order('position') }, :dependent => :destroy
	has_many :lectures, -> { order('position') }
	has_many :quizzes, -> { order('position') }
	has_many :custom_links, -> { order('position') }
	has_many :announcements, :dependent => :destroy
	has_many :confuseds
	
	has_many :enrollments, :dependent => :destroy
	# has_many :users, :through => :enrollments
	has_many :users, :through => :enrollments, :source => :user

	has_many :teacher_enrollments, :dependent => :destroy
	has_many :teachers, :through => :teacher_enrollments, :source => :user  # to get this call user.subjects


	has_many :guest_enrollments, :dependent => :destroy
	has_many :guests, :source => :user, :through => :guest_enrollments

	has_many :course_domains, :dependent => :destroy
	has_many :invitations, :dependent => :destroy
	has_many :assignment_statuses, :dependent => :destroy
	has_many :assignment_item_statuses, :dependent => :destroy
	has_many :distance_peers
	has_many :events, :dependent => :destroy
	has_many :free_online_quiz_grades
	has_many :inclass_sessions
	has_many :lecture_views
	has_many :online_markers
	has_many :online_quiz_grades
	has_many :online_quizzes
	has_many :video_events

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

	def import_course(import_from)
		importing_will_change!
		
		from=Course.find(import_from)
		
		addition_days = ((self.start_date.to_date - from.start_date.to_date) .to_i).days

		new_course=self
		
		from.groups.each do |g|
			new_group= g.dup
			new_group.course_id = new_course.id
			new_group.appearance_time = g.appearance_time + addition_days
			new_group.due_date = g.due_date + addition_days
			new_group.save(:validate => false)
			g.lectures.each do |l|
				new_lecture= l.dup
				new_lecture.course_id = new_course.id
				new_lecture.group_id = new_group.id
				new_lecture.appearance_time = l.appearance_time + addition_days
				new_lecture.due_date = l.due_date + addition_days
				new_lecture.save(:validate => false)
				### waiting for online markers table
				# l.online_markers.each do |marker|
				# 	new_online_marker = marker.dup
				# 	new_online_marker.lecture_id = new_lecture.id
				# 	new_online_marker.group_id = new_group.id
				# 	new_online_marker.course_id = new_course.id
				# 	new_online_marker.hide = false
				# 	new_online_marker.save(:validate => false)
				# end
				# l.online_quizzes.each do |quiz|
				# 	new_online_quiz = quiz.dup
				# 	new_online_quiz.lecture_id = new_lecture.id
				# 	new_online_quiz.group_id = new_group.id
				# 	new_online_quiz.course_id = new_course.id
				# 	new_online_quiz.hide = true
				# 	new_online_quiz.save(:validate => false)
				# 	if new_online_quiz.inclass
				# 		new_online_quiz.create_inclass_session(:status => 0, :lecture_id => new_online_quiz.lecture_id, :group_id => new_online_quiz.group_id, :course_id => new_online_quiz.course_id)
				# 	end
				# 	quiz.online_answers.each do |answer|
				# 		new_answer = answer.dup
				# 		new_answer.online_quiz_id = new_online_quiz.id
				# 		new_answer.save(:validate => false)
				# 	end
				# end
				### waiting for events table
				# Event.where(:quiz_id => nil, :lecture_id => l.id).each do |e|
				# 	new_event= e.dup
				# 	new_event.lecture_id = new_lecture.id
				# 	new_event.course_id = new_course.id
				# 	new_event.group_id = new_group.id
				# 	new_event.start_at = e.start_at + addition_days
				# 	new_event.end_at = e.end_at + addition_days
				# 	new_event.save(:validate => false)
				# end

			end
			g.quizzes.each do |q|
				new_quiz= q.dup
				new_quiz.course_id = new_course.id
				new_quiz.group_id = new_group.id
				new_quiz.visible= false
				if from.end_date.to_time < q.appearance_time 
					new_quiz.appearance_time =  Date.today + 200.years
				else
					new_quiz.appearance_time =  new_group.appearance_time
				end
				new_quiz.due_date = new_quiz.due_date + addition_days
				new_quiz.save(:validate => false)

				### waiting for events table
				# Event.where(:quiz_id => q.id, :lecture_id => nil).each do |e|
				# 	new_event= e.dup
				# 	new_event.quiz_id = new_quiz.id
				# 	new_event.course_id = new_course.id
				# 	new_event.group_id = new_group.id
				# 	new_event.start_at = Date.today + 200.years
				# 	new_event.end_at = Date.today + 200.years
				# 	new_event.save(:validate => false)
				# end

				q.questions.each do |question|
					new_question = question.dup
					new_question.quiz_id = new_quiz.id
					new_question.show = false
					new_question.student_show = false
					new_question.save(:validate => false)

					question.answers.each do |answer|
						new_answer = answer.dup
						new_answer.question_id = new_question.id
						new_answer.save(:validate => false)
					end
				end
			end
			g.custom_links.each do |d|
				new_link= d.dup
				new_link.course_id = new_course.id
				new_link.group_id = new_group.id
				new_link.save(:validate => false)
			end

			### waiting for events table
			# g.events.where(:quiz_id => nil, :lecture_id => nil).each do |e|
			# 	new_event= e.dup
			# 	new_event.course_id = new_course.id
			# 	new_event.group_id = new_group.id
			# 	new_event.save(:validate => false)
			# 	new_event.start_at = e.start_at + addition_days
			# 	new_event.end_at = e.end_at + addition_days
			# end
		end
		self.importing = false
		self.save!

  	end
  	handle_asynchronously :import_course, :run_at => Proc.new { 15.seconds.from_now }


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
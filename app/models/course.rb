class Course < ApplicationRecord
	include HelperUtils


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
	has_many :quiz_statuses

	validates :name, :end_date, :short_name,:start_date, :user_id, :time_zone, :presence => true

	before_create :create_unique_identifier
	before_create :create_guest_unique_identifier

	validate :unique_identifier_guest_unique_identifier_not_changed

	validate :validate_end_date_disable_regis_after_start_date ,on: [:create, :update]
	validates_format_of :image_url, :with    => %r{\.(((g|G)(i|I)(f|F))|((j|J)(p|P)(e|E)?(g|G))|((p|P)(n|N)(g|G)))}i, :message => :must_be_image, :allow_blank => true
	
	attribute :modules
	attribute :duration
	
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
			if user_role.admin_school_domain != 'all' 
					email = user_role.admin_school_domain || nil 
			else 
					email = user_role.organization.domain || nil 
			end 
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
		if self.end_date && self.start_date
			( self.end_date - self.start_date ).numerator / 7
		end
		
	end

	def is_teacher(user)
		self.teachers.where(:id => user.id).count>0
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

	def export_course(current_user)
			@course = Course.where(:id => id).includes([:groups , :custom_links, {:quizzes => [{:questions => :answers}, :quiz_statuses, :quiz_grades, :free_answers]},:lectures, :lecture_views, :confuseds, :free_online_quiz_grades, :online_quiz_grades, {:online_quizzes => :online_answers}, :announcements, :assignment_statuses])[0]

			csv_files={}

			csv_files[:course]= CSV.generate do |csv_course|
			csv_files[:groups]= CSV.generate do |csv_group|
			csv_files[:lectures] = CSV.generate do |csv_lecture|
			csv_files[:quizzes] = CSV.generate do |csv_quiz|
			csv_files[:online_quizzes] = CSV.generate do |csv_online_quiz|
			csv_files[:online_answers] = CSV.generate do |csv_online_answer|
			csv_files[:questions]= CSV.generate do |csv_question|
			csv_files[:answers]= CSV.generate do |csv_answer|
			csv_files[:custom_links]= CSV.generate do |csv_link|
			csv_files[:lecture_views]= CSV.generate do |csv_lecture_view|
			csv_files[:online_quiz_grades]= CSV.generate do |csv_online_quiz_grade|
			csv_files[:free_online_quiz_grades]= CSV.generate do |csv_free_online_quiz_grade|
			csv_files[:confused]= CSV.generate do |csv_confused|
			csv_files[:lecture_questions]= CSV.generate do |csv_lecture_question|
			csv_files[:discussions] = CSV.generate do |csv_discussion|
			csv_files[:pauses]= CSV.generate do |csv_pause|
			csv_files[:backs]= CSV.generate do |csv_back|
			csv_files[:quiz_statuses]= CSV.generate do |csv_quiz_status|
			csv_files[:quiz_grades]= CSV.generate do |csv_quiz_grade|
			csv_files[:free_answers]= CSV.generate do |csv_free_answer|
			csv_files[:announcements]= CSV.generate do |csv_announcement|
			csv_files[:assignment_statuses]= CSV.generate do |csv_assignment_status|
			csv_files[:enrollments]= CSV.generate do |csv_enrollment|
			csv_files[:teacher_enrollments]= CSV.generate do |csv_teacher_enrollment|
			csv_files[:events]= CSV.generate do |csv_events|

					csv_course << Course.column_names
					csv_course << @course.attributes.values_at(*Course.column_names)

					csv_group << Group.column_names
					csv_lecture << Lecture.column_names
					csv_quiz << Quiz.column_names
					csv_online_quiz << OnlineQuiz.column_names
					csv_online_answer << OnlineAnswer.column_names
					csv_question << Question.column_names
					csv_answer << Answer.column_names
					csv_link << CustomLink.column_names
					csv_lecture_view << LectureView.column_names
					csv_online_quiz_grade << OnlineQuizGrade.column_names
					csv_free_online_quiz_grade << FreeOnlineQuizGrade.column_names
					csv_confused << Confused.column_names
					# csv_lecture_question << LectureQuestion.column_names
					csv_discussion << Forum::Post.get('column_names')
					csv_pause << VideoEvent.column_names
					csv_back<< VideoEvent.column_names
					csv_quiz_status << QuizStatus.column_names
					csv_assignment_status << AssignmentStatus.column_names
					csv_quiz_grade << QuizGrade.column_names
					csv_free_answer << FreeAnswer.column_names
					csv_announcement << Announcement.column_names
					csv_enrollment << Enrollment.column_names
					csv_teacher_enrollment  << TeacherEnrollment.column_names
					csv_events  << Event.column_names

					@course.assignment_statuses.each do |assignment_status|
							csv_assignment_status << assignment_status.attributes.values_at(* AssignmentStatus.column_names)
					end
					@course.announcements.each do |announcement|
							csv_announcement << announcement.attributes.values_at(* Announcement.column_names)
					end
					# @course.groups.each
					@course.groups.each do |g|
							csv_group << g.attributes.values_at(* Group.column_names)
					end

					@course.lectures.each do |l|
									csv_lecture << l.attributes.values_at(* Lecture.column_names)
									Forum::Post.find(:all, :params => {lecture_id: l.id}).each do |p|
											csv_discussion << p.attributes.values_at(* Forum::Post.get('column_names'))
									end
					end

					@course.online_quizzes.each do |quiz|
							csv_online_quiz << quiz.attributes.values_at(* OnlineQuiz.column_names)
							quiz.online_answers.each do |answer|
									csv_online_answer << answer.attributes.values_at(* OnlineAnswer.column_names)
							end
					end

					@course.lecture_views.each do |lecture_view|
							csv_lecture_view << lecture_view.attributes.values_at(* LectureView.column_names)
					end
					@course.online_quiz_grades.each do |online_quiz_grade|
							csv_online_quiz_grade << online_quiz_grade.attributes.values_at(* OnlineQuizGrade.column_names)
					end
					@course.free_online_quiz_grades.each do |free_online_quiz_grade|
							csv_free_online_quiz_grade << free_online_quiz_grade.attributes.values_at(* FreeOnlineQuizGrade.column_names)
					end
					@course.confuseds.each do |confused|
							csv_confused << confused.attributes.values_at(* Confused.column_names)
					end
					# @course.lecture_questions.each do |lecture_question|
					# 		csv_lecture_question << lecture_question.attributes.values_at(* LectureQuestion.column_names)
					# end
					@course.video_events.where(:event_type => 2).each do |pause|
							csv_pause << pause.attributes.values_at(* VideoEvent.column_names)
					end
					@course.video_events.where("event_type = 3 and (from_time - to_time) <= 15 and (from_time - to_time) >= 1").each do |back|
							csv_back << back.attributes.values_at(* VideoEvent.column_names)
					end

					@course.quizzes.each do |q|
									csv_quiz << q.attributes.values_at(* Quiz.column_names)
									q.questions.each do |question|
											csv_question << question.attributes.values_at(* Question.column_names)
											question.answers.each do |answer|
													csv_answer << answer.attributes.values_at(* Answer.column_names)
											end
									end
									q.quiz_statuses.each do |quiz_status|
					csv_quiz_status << quiz_status.attributes.values_at(* QuizStatus.column_names)
									end
									q.quiz_grades.each do |quiz_grade|
					csv_quiz_grade << quiz_grade.attributes.values_at(* QuizGrade.column_names)
									end
									q.free_answers.each do |free_answer|
					csv_free_answer << free_answer.attributes.values_at(* FreeAnswer.column_names)
									end
					end
					@course.custom_links.each do |d|
							csv_link << d.attributes.values_at(* CustomLink.column_names)
					end

					@course.enrollments.each do |d|
							csv_enrollment << d.attributes.values_at(* Enrollment.column_names)
					end

					@course.teacher_enrollments.each do |d|
							csv_teacher_enrollment << d.attributes.values_at(* TeacherEnrollment.column_names)
					end

					@course.events.each do |d|
							csv_events << d.attributes.values_at(* Event.column_names)
					end

			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end
			end

			######## This is working - creates csv's and then puts them in zip #############
			file_name = sanitize_filename(@course.short_name)+".zip"

			t = Tempfile.new(file_name)
			Zip::ZipOutputStream.open(t.path) do |z|
					csv_files.each do |key,value|
						z.put_next_entry("#{key}.csv")
						z.write(value)
					end
			end
			#send_file t.path, :type => 'application/zip',
			#                  :disposition => 'attachment',
			#                  :filename => file_name
			UserMailer.delay.attachment_email(current_user, file_name, t.path, I18n.locale)#.deliver
			t.close
	end
	handle_asynchronously :export_course, :run_at => Proc.new { 5.seconds.from_now }


	def export_student_csv(current_user)
    enrolled = User.where('enrollments.course_id = ?',id).includes(:enrollments)
    csv_files={}
    csv_files[:student_list]= CSV.generate do |csv_student_list|
      csv_student_list  << [:email ,:name , :last_name ,:screen_name,:university]
      enrolled.each do |d|
        csv_student_list << [d.email ,d.name , d.last_name ,d.screen_name , d.university]
      end
    end

    ######## This is working - creates csv's and then puts them in zip #############
    file_name = sanitize_filename(self.short_name)+".zip"#{}"course.zip"

    t = Tempfile.new(file_name)
    Zip::ZipOutputStream.open(t.path) do |z|
      csv_files.each do |key,value|
       z.put_next_entry("#{key}.csv")
       z.write(value)
      end
    end
    #send_file t.path, :type => 'application/zip',
    #                  :disposition => 'attachment',
    #                  :filename => file_name
    UserMailer.delay.attachment_email(current_user, file_name, t.path, I18n.locale)#.deliver
    t.close
  end
  handle_asynchronously :export_student_csv, :run_at => Proc.new { 5.seconds.from_now }


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
				l.online_markers.each do |marker|
					new_online_marker = marker.dup
					new_online_marker.lecture_id = new_lecture.id
					new_online_marker.group_id = new_group.id
					new_online_marker.course_id = new_course.id
					new_online_marker.hide = false
					new_online_marker.save(:validate => false)
				end
				l.online_quizzes.each do |quiz|
					new_online_quiz = quiz.dup
					new_online_quiz.lecture_id = new_lecture.id
					new_online_quiz.group_id = new_group.id
					new_online_quiz.course_id = new_course.id
					new_online_quiz.hide = true
					new_online_quiz.save(:validate => false)
					if new_online_quiz.inclass
						new_online_quiz.create_inclass_session(:status => 0, :lecture_id => new_online_quiz.lecture_id, :group_id => new_online_quiz.group_id, :course_id => new_online_quiz.course_id)
					end
					quiz.online_answers.each do |answer|
						new_answer = answer.dup
						new_answer.online_quiz_id = new_online_quiz.id
						new_answer.save(:validate => false)
					end
				end
				Event.where(:quiz_id => nil, :lecture_id => l.id).each do |e|
					new_event= e.dup
					new_event.lecture_id = new_lecture.id
					new_event.course_id = new_course.id
					new_event.group_id = new_group.id
					new_event.start_at = e.start_at + addition_days
					new_event.end_at = e.end_at + addition_days
					new_event.save(:validate => false)
				end

			end
			g.quizzes.each do |q|
				new_quiz= q.dup
				new_quiz.course_id = new_course.id
				new_quiz.group_id = new_group.id
				new_quiz.visible= false
				if from.end_date.to_time < q.appearance_time 
					new_quiz.appearance_time =  Date.today + 200.years
				else
					new_quiz.appearance_time =  g.appearance_time
				end
				new_quiz.due_date = new_quiz.due_date + addition_days
				new_quiz.save(:validate => false)

				Event.where(:quiz_id => q.id, :lecture_id => nil).each do |e|
					new_event= e.dup
					new_event.quiz_id = new_quiz.id
					new_event.course_id = new_course.id
					new_event.group_id = new_group.id
					new_event.start_at = Date.today + 200.years
					new_event.end_at = Date.today + 200.years
					new_event.save(:validate => false)
				end

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

			g.events.where(:quiz_id => nil, :lecture_id => nil).each do |e|
				new_event= e.dup
				new_event.course_id = new_course.id
				new_event.group_id = new_group.id
				new_event.save(:validate => false)
				new_event.start_at = e.start_at + addition_days
				new_event.end_at = e.end_at + addition_days
			end
		end
		self.importing = false
		self.save!

	end
	handle_asynchronously :import_course, :run_at => Proc.new { 15.seconds.from_now }


	# def self.our(user)
	# end

	def enrolled_students #returns scope (relation)
		return users
	end

	# def not_enrolled_students #returns scope (relation)
	# end

  def export_for_transfer
    @course = Course.where(:id => id).includes([:groups , :custom_links, {:quizzes => [{:questions => :answers}, :quiz_statuses, :quiz_grades, :free_answers]},:lectures, :lecture_views, :confuseds, :pauses, :backs, :lecture_questions, :free_online_quiz_grades, :online_quiz_grades, {:online_quizzes => :online_answers}, :announcements, :assignment_statuses])[0]

    csv_files={}

    csv_files[:course]= CSV.generate do |csv_course|
    csv_files[:groups]= CSV.generate do |csv_group|
    csv_files[:lectures] = CSV.generate do |csv_lecture|
    csv_files[:quizzes] = CSV.generate do |csv_quiz|
    csv_files[:online_quizzes] = CSV.generate do |csv_online_quiz|
    csv_files[:online_answers] = CSV.generate do |csv_online_answer|
    csv_files[:questions]= CSV.generate do |csv_question|
    csv_files[:answers]= CSV.generate do |csv_answer|
    csv_files[:custom_links]= CSV.generate do |csv_link|
    csv_files[:free_answers]= CSV.generate do |csv_free_answer|
    csv_files[:events]= CSV.generate do |csv_events|
    csv_files[:teacher_enrollments]= CSV.generate do |csv_teacher_enrollment|
    csv_files[:teacher]= CSV.generate do |csv_teacher|

      csv_course << Course.column_names
      csv_course << @course.attributes.values_at(*Course.column_names)

      csv_group << Group.column_names
      csv_lecture << Lecture.column_names
      csv_quiz << Quiz.column_names
      csv_online_quiz << OnlineQuiz.column_names
      csv_online_answer << OnlineAnswer.column_names
      csv_question << Question.column_names
      csv_answer << Answer.column_names
      csv_link << CustomLink.column_names
      csv_free_answer << FreeAnswer.column_names
      csv_events  << Event.column_names
      csv_teacher_enrollment  << TeacherEnrollment.column_names + ["email"]
      csv_teacher << ["email"]

      @course.groups.each do |g|
        csv_group << g.attributes.values_at(* Group.column_names)
      end

      @course.lectures.each do |l|
          csv_lecture << l.attributes.values_at(* Lecture.column_names)
      end

      @course.online_quizzes.each do |quiz|
        csv_online_quiz << quiz.attributes.values_at(* OnlineQuiz.column_names)
        quiz.online_answers.each do |answer|
          csv_online_answer << answer.attributes.values_at(* OnlineAnswer.column_names)
        end
      end

      @course.quizzes.each do |q|
          csv_quiz << q.attributes.values_at(* Quiz.column_names)
          q.questions.each do |question|
            csv_question << question.attributes.values_at(* Question.column_names)
            question.answers.each do |answer|
              csv_answer << answer.attributes.values_at(* Answer.column_names)
            end
          end

          q.free_answers.each do |free_answer|
      csv_free_answer << free_answer.attributes.values_at(* FreeAnswer.column_names)
          end
      end
      @course.custom_links.each do |d|
        csv_link << d.attributes.values_at(* CustomLink.column_names)
      end

      @course.events.each do |d|
        csv_events << d.attributes.values_at(* Event.column_names)
      end

      @course.teacher_enrollments.each do |d|
        csv_teacher_enrollment << d.attributes.values_at(* TeacherEnrollment.column_names) + [User.find(d.user_id).email]
      end

      csv_teacher << @course.user.attributes.values_at("email")


    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
    end
      return csv_files
  end

	def export_modules_progress(current_user)
		students=self.users.select("users.*, LOWER(users.name), LOWER(users.last_name)").order("LOWER(users.last_name)").includes([{:free_online_quiz_grades => :lecture}, {:online_quiz_grades => :lecture}, {:lecture_views => :lecture}, {:quiz_statuses => :quiz},:assignment_statuses])
		course_groups = self.groups.sort{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }
		module_names= course_groups.map{|m| m.name}
		csv_file = CSV.generate do |csv_course|
		csv_course << ["student_last", "student_first", "student_email", "total_late_days"]+module_names

		students.each do |s|
			grades=s.group_grades_test(self)  #returns for each module in the course, whether student finished r not and on time or not.
				s.assignment_statuses.each do |stat|
					if stat.status == 1
						grades[stat.group_id] = 0
					elsif stat.status == 2
						grades[stat.group_id] = -1
					end
				end
				late_total = 0
				student_grades = []
				course_groups.each do |g|
					if(grades[g.id] != -1)
						late_total+= grades[g.id]
						student_grades << grades[g.id]
					else
						student_grades << "-"
					end
				end
				csv_course << [s.last_name, s.name, s.email, late_total]+student_grades
			end
			csv_course << ["Number indicates number of days late."]
			csv_course << ["0 days late means completed on-time. "]
			csv_course << ["'-' means did not finished."]
		end


		sanitized_file_name = sanitize_filename(short_name)
		file_name = sanitized_file_name+"_progress_days_late.zip"
		t = Tempfile.new(file_name)
		csv_file_name = sanitized_file_name+"_progress_days_late.csv"

		Zip::ZipOutputStream.open(t.path) do |z|
		z.put_next_entry(csv_file_name)
		z.write(csv_file)
		end
		
		UserMailer.progress_days_late(current_user, file_name, t.path, I18n.locale,self).deliver
		t.close
	end
	# handle_asynchronously :export_modules_progress, :run_at => Proc.new { 5.seconds.from_now }

	def self.school_admin_statistics_course_ids(raw_start_date, raw_end_date, domain = 'All', current_user)
			# raw_start_date = "01-December-2016" #start_date
			# raw_end_date = "10-January-2017" #end_date
			if domain.nil?
					domain == 'All'
			end
			start_date = DateTime.parse(raw_start_date).midnight
			end_date = DateTime.parse(raw_end_date).midnight

			school_course = Course.includes([:user,:teachers])
			if (!current_user.is_administrator? &&  domain.downcase == 'all')
					domain = UsersRole.where(:user_id => current_user.id, :role_id => 9)[0].admin_school_domain
					if domain == 'all'
							email = user_role.organization.domain || nil
					end

			end

			if(domain.downcase != "all")
					school_course = school_course.select{|c| c.teachers.select{|t| t.email.split("@").last.include?(domain) }.size>0}
			end
			course_ids = school_course.map{|c| c.id}

			course_quizzes = Quiz.select("id, course_id, updated_at").where(:course_id => course_ids)
			course_quizzes_ids = course_quizzes.map(&:id)
			course_quizzes_map = {}
			course_quizzes.each{|q| course_quizzes_map[q.id] = q.course_id}

			course_lectures = Lecture.select("id, course_id, updated_at").where(:course_id => course_ids)
			course_lectures_ids = course_lectures.map(&:id)
			course_lectures_map = {}
			course_lectures.each{|l| course_lectures_map[l.id] = l.course_id}

			new_updated_courses = school_course.map{|c|  c.id if c.updated_at.between?(start_date,end_date) }
			course_quiz_solved = QuizGrade.where("updated_at between ? and ? and quiz_id in (?)", start_date, end_date, course_quizzes_ids).pluck("distinct quiz_id").map{|quiz_id| course_quizzes_map[quiz_id]}
			course_updated_note = VideoNote.where("updated_at between ? and ? and lecture_id in (?)", start_date, end_date, course_lectures_ids).pluck("distinct lecture_id").map{|lecture_id| course_lectures_map[lecture_id]}
			course_created_lec_views = LectureView.where("created_at between ? and ? AND course_id IN (?)", start_date, end_date, course_ids).pluck("distinct course_id")
			course_updated_confused = Confused.where("updated_at between ? and ? AND course_id IN (?)", start_date, end_date, course_ids).pluck("distinct course_id")
			course_updated_modules = Group.where("updated_at between ? and ? AND course_id IN (?)", start_date, end_date, course_ids).pluck("distinct course_id")
			course_updated_lectures = course_lectures.map{|l|  l.course_id if l.updated_at.between?(start_date,end_date) }
			course_updated_quizzes = course_quizzes.map{|q|  q.course_id if q.updated_at.between?(start_date,end_date) }
			course_updated_links = CustomLink.where("updated_at between ? and ? AND course_id IN (?)", start_date, end_date, course_ids).pluck("distinct course_id")
			course_announcements = Announcement.where("updated_at between ? and ? AND course_id IN (?)", start_date, end_date, course_ids).pluck("distinct course_id")

			course_online_quiz_grade = OnlineQuizGrade.where("updated_at between ? and ? AND course_id IN (?) AND attempt = 1", start_date, end_date, course_ids).pluck("distinct course_id")
			course_free_online_quiz_grades = FreeOnlineQuizGrade.where("updated_at between ? and ? AND course_id IN (?) AND attempt = 1", start_date, end_date, course_ids).pluck("distinct course_id")

			active_courses_ids = (new_updated_courses + course_created_lec_views + course_quiz_solved + course_updated_note + course_updated_confused + course_updated_modules + course_updated_lectures + course_updated_quizzes + course_updated_links + course_announcements +course_online_quiz_grade +course_free_online_quiz_grades).uniq
			active_courses_ids = active_courses_ids.compact

			total_teachers_count  = TeacherEnrollment.select("distinct user_id").where(:course_id => active_courses_ids).count    
			total_students_count  = Enrollment.select("distinct user_id").where(:course_id => active_courses_ids).count

			active_courses_count = active_courses_ids.size
			total_lectures_count = course_lectures_ids.size

			totals={
					total_courses: active_courses_count,
					total_students: total_students_count,
					total_teachers: total_teachers_count,
					total_lectures: total_lectures_count,
					course_ids: active_courses_ids,
			}
			return totals
	end

	def self.school_admin_statistics_course_data(raw_start_date, raw_end_date, active_courses_ids)
			# raw_start_date = "01-December-2016" #start_date
			# raw_end_date = "10-January-2017" #end_date
			start_date = DateTime.parse(raw_start_date).midnight
			end_date = DateTime.parse(raw_end_date).midnight
			total_teachers = TeacherEnrollment.where(:course_id => active_courses_ids).group_by{|a| a.course_id}
			total_teachers.each{|course_id,teacher_list| total_teachers[course_id] = teacher_list.map{|teacher| teacher.user_id}}

			total_students = Enrollment.where(:course_id => active_courses_ids).group_by{|a| a.course_id}
			total_students_course = {}
			total_students.each{|course_id,student_list| list = student_list.map{|student| student.user_id}; total_students[course_id] = list; total_students_course[course_id] =list.count  }

			questions ={'active_courses' => {},'total_courses' => {}, 'total_questions' => 0, 'comments_user_id'=> {}}
			active_courses_ids.in_groups_of(50 ,false) do |course_ids|
					part_question = Forum::Post.get("posts_count", {:start_date =>raw_start_date, :end_date => raw_end_date, :course_ids => course_ids })
					questions["active_courses"] = questions["active_courses"].merge(part_question['active_courses'])
					questions["total_courses"] = questions["total_courses"].merge(part_question['total_courses'])
					questions["total_questions"] += part_question['total_questions']
					questions["comments_user_id"] = questions["comments_user_id"].merge(part_question['comments_user_id'])
			end


			total_questions_answered_students = 0
			total_questions_answered_teachers = 0
			questions["comments_user_id"].each do |course_id, comment_users|
					teachers = total_teachers[course_id.to_i]||[]
					students = total_students[course_id.to_i]||[]
					users = {}
					counts = {"teacher" => 0, "student" => 0 ,  "missing" => 0}

					teachers.each_with_object(users){ |user_id, obj| obj[user_id] = "teacher" }
					students.each_with_object(users){ |user_id, obj| obj[user_id] = "student" }
					comment_users.each{ |cu| counts[users[cu.to_i] || "missing"] += 1 }

					total_questions_answered_teachers += counts["teacher"]
					total_questions_answered_students += counts["student"]
			end

			group_lec_views_by_course = LectureView.joins(:lecture).where("lecture_views.created_at between ? and ? AND lecture_views.course_id IN (?)", start_date, end_date, active_courses_ids).group('lecture_views.course_id, lecture_views.lecture_id').select('lecture_views.lecture_id, lecture_views.course_id , ( (SUM(percent)/100) * (SUM(duration)/count(*)) ) as views ').group_by(&:course_id)
			total_group_lec_views_by_course = LectureView.joins(:lecture).where("lecture_views.course_id IN (?)", active_courses_ids).group('lecture_views.course_id, lecture_views.lecture_id').select('lecture_views.lecture_id, lecture_views.course_id , ( (SUM(percent)/100) * (SUM(duration)/count(*)) ) as views ').group_by(&:course_id)
			active_courses = Course.where(id: active_courses_ids)

			course_data ={}
			active_courses.each do |course|
					course_data[course.id] = {
							'short_name' => course.short_name,
							'start_date' => course.start_date,
							'end_date' => course.end_date,
							'full_name' => course.user.full_name_reverse,
							'email' => course.user.email,
							'teachers' => course.teachers.size || 0,
							'students' => total_students_course[course.id] || 0,
							'active_questions' => questions['active_courses'][course.id.to_s] || 0,
							'total_questions' => questions['total_courses'][course.id.to_s] || 0,
							'active_solved_online_quiz' => 0,
							'total_solved_online_quiz' => 0,
							'active_view' => (group_lec_views_by_course[course.id].map{|l| l.views.to_i}.sum rescue 0),
							'total_view' => (total_group_lec_views_by_course[course.id].map{|l| l.views.to_i}.sum rescue 0)
					}
			end

			active_sum_online_quiz_grade = OnlineQuizGrade.where("updated_at between ? and ? AND course_id IN (?) AND attempt = 1", start_date, end_date, active_courses_ids).group('course_id').select('course_id , (COUNT(*)) as count ')
			active_sum_free_online_quiz_grades = FreeOnlineQuizGrade.where("updated_at between ? and ? AND course_id IN (?)  AND attempt = 1", start_date, end_date, active_courses_ids).group('course_id').select('course_id , (COUNT(*)) as count ')
			active_sum_online_quiz_grade.each{|course_count| course_data[course_count.course_id]['active_solved_online_quiz'] += course_count.count.to_i}
			active_sum_free_online_quiz_grades.each{|course_count| course_data[course_count.course_id]['active_solved_online_quiz'] += course_count.count.to_i}

			total_online_quiz_grade = OnlineQuizGrade.where("course_id IN (?) AND attempt = 1", active_courses_ids ).group('course_id').select('course_id , (COUNT(*)) as count')
			total_free_online_quiz_grades = FreeOnlineQuizGrade.where("course_id IN (?) AND attempt = 1", active_courses_ids ).group('course_id').select('course_id , (COUNT(*)) as count')
			total_online_quiz_grade.each{|course_count| course_data[course_count.course_id]['total_solved_online_quiz'] += course_count.count.to_i}
			total_free_online_quiz_grades.each{|course_count| course_data[course_count.course_id]['total_solved_online_quiz'] += course_count.count.to_i}

			total_hours = course_data.map { |e| e[1]["active_view"] }.sum
			total_online_quiz_solved_count = active_sum_online_quiz_grade.map { |e| e.count.to_i }.sum + active_sum_free_online_quiz_grades.map { |e| e.count.to_i }.sum

			totals={
					total_hours: total_hours,
					total_online_quiz_solved: total_online_quiz_solved_count ,
					total_questions: questions['total_questions'] ,
					total_questions_answered_students: total_questions_answered_students,
					total_questions_answered_teachers: total_questions_answered_teachers,

					course_data: course_data
			}
			return totals
	end

  class << self
    def export_school_data(start_date, end_date, domain, current_user)
      totals = Course.school_admin_statistics(start_date, end_date, domain, current_user)
      csv_file = CSV.generate do |csv_course|
        csv_course << ["course_name", "teacher_name", "active_students", "questions", "solved_quizzes", "view", "start_date", "end_date", "teacher_email", "active_teachers", "total_questions", "total_solved_quizzes", "total_view"]
        totals[:course_data].each do |course_data|
          course = course_data[1]
          csv_course << [course["short_name"], course["full_name"], course["students"], course["active_questions"], course["active_solved_online_quiz"], course["active_view"], course["start_date"], course["end_date"], course["email"], course["teachers"], course["total_questions"], course["total_solved_online_quiz"], course["total_view"]]
        end
      end
      file_name = "#{current_user.email.split('@')[1]}_school_data.zip"
      t = Tempfile.new(file_name)
      csv_file_name = "#{current_user.email.split('@')[1]}_school_data.csv"

      Zip::ZipOutputStream.open(t.path) do |z|
       z.put_next_entry(csv_file_name)
       z.write(csv_file)
      end

      UserMailer.delay.attachment_email(current_user, file_name, t.path, I18n.locale)
      # UserMailer.attachment_email(current_user, file_name, t.path, I18n.locale).deliver
      t.close
    end
    handle_asynchronously :export_school_data, :run_at => Proc.new { 5.seconds.from_now }
  end

  ## workaround for delayed jobs to work on class methods
  def self.export_school_admin(start_date, end_date, domain, current_user)
    Course.export_school_data(start_date, end_date, domain, current_user)
  end

	private 
		# def validate_end_date_after_start_date
		def validate_end_date_disable_regis_after_start_date
			if end_date && start_date && end_date < start_date
				errors.add(:end_date, I18n.t("courses.errors.end_date_pass") )
			end
			if disable_registration && disable_registration < start_date
				errors.add(:disable_registration, I18n.t("courses.errors.end_date_pass") )
			end
		end

		def unique_identifier_guest_unique_identifier_not_changed
			if unique_identifier_changed?  && self.persisted?
				errors.add(:unique_identifier, I18n.t("courses.errors.unique_identifier_changed")  )
			end
			if guest_unique_identifier_changed? && self.persisted?
				errors.add(:guest_unique_identifier, I18n.t("courses.errors.guest_unique_identifier_changed") )
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

class ActiveSupport::TimeWithZone
  def to_s(format = :default)
   self.to_datetime.to_s(:db)
  end
end
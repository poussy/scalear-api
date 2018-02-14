class CoursesController < ApplicationController
	load_and_authorize_resource
				#  @course is aready loaded  

	# # # before_filter :correct_user, :except => [:index, :new, :create, :enroll_to_course, :course_copy_angular, :get_all_teachers, :current_courses, :send_system_announcement]
	before_action :importing?, :except => [:index, :new, :create, :enroll_to_course, :course_copy_angular, :get_all_teachers, :current_courses, :send_system_announcement, :get_role]
	before_action :set_zone , :except => [:index, :new, :create, :enroll_to_course, :course_copy_angular, :get_all_teachers, :current_courses, :send_system_announcement, :get_role]

	def create
		params[:course][:user_id]=current_user.id
		import_from= params[:import]
		@course = Course.new(course_params)
		if @course.save
			@course.add_professor(current_user , params[:email_discussion])
			params[:subdomains].each do |subdomain_key, subdomain_boolean|
				if subdomain_key != "All" && subdomain_boolean
					@course.course_domains.create(:domain => subdomain_key)
				end
			end
			if !import_from.blank?
				@course.update_attributes(:importing => true)
				@course.import_course(import_from)
				#Delayed::Job.enqueue @course.import_course(import_from)
				# check user enter Description or Prerequisites
				render json: {course:@course, :notice => [ I18n.t("controller_msg.importing_course_data") ], :importing => true}, status: :created
			else
				render json: {course:@course, :notice => [ I18n.t("controller_msg.course_successfully_created") ], :importing => false}, status: :created
			end
		else
			@import = current_user.subjects
			render json: {errors: @course.errors}, status: :unprocessable_entity 
		end
	end

	# # Removed to course model for cancancan
	# # def correct_user
	# # end  

	def set_zone
		Time.zone= @course.time_zone
	end

	def importing?
		if @course.importing==true
			render json: {:errors => [ I18n.t("controller_msg.you_are_not_authorized") ]}, status: 403
		end		
	end  

	def index
		if current_user.has_role?('Administrator')
			@total_teacher = Course.where("id is not null").count
			teacher_courses= Course.where("id is not null").order("start_date DESC").limit(params[:limit]).offset(params[:offset]).includes([{:teacher_enrollments => [:user,:role]}, :enrollments, :lectures, :quizzes])#.all
		elsif current_user.is_school_administrator?
			email = UsersRole.where(:user_id => current_user.id, :role_id => 9)[0].admin_school_domain
			if email.blank?
				@total_teacher = 0
				teacher_courses = {}
			else
				@total_teacher = Course.select{|c| c.teachers.select{|t| t.email.include?(email) }.size>0}.count
				teacher_courses = Course.order("start_date DESC").includes([:user,:teachers,{:teacher_enrollments => [:user,:role]}, :enrollments, :lectures, :quizzes]).select{|c| c.teachers.select{|t| t.email.include?(email) }.size>0}[params[:offset].to_i .. params[:offset].to_i+params[:limit].to_i ]
			end
		else
			@total_teacher = current_user.subjects_to_teach.count
			teacher_courses = current_user.subjects_to_teach.order("start_date DESC").limit(params[:limit]).offset(params[:offset]).includes([{:teacher_enrollments => [:user,:role]}, :enrollments, :lectures, :quizzes])
		end
		if teacher_courses 
			teacher_courses = teacher_courses.map do|c| 
				{ 
					"end_date"=>c.end_date,"id"=>c.id,"importing"=>c.importing,"image_url"=>c.image_url,"name"=>c.name,"short_name"=>c.short_name, 
					"start_date"=>c.start_date,"user_id"=>c.user_id,"ended"=>c.ended,"duration"=>c.duration,'enrollments'=>c.enrollments.size ,'lectures'=>c.lectures.size , 
					'quiz'=>c.quizzes.select{|q| q.quiz_type =='quiz'}.size ,'survey'=>c.quizzes.select{|q| q.quiz_type !='quiz'}.size, 
					"teacher_enrollments"=> c.teacher_enrollments.map { |u| { "user" => { "name" => u.user.name , "email" => u.user.email } } } 
				} 
			end 
		end 
		@total_student = (current_user.courses + current_user.guest_courses).count
		student_courses = (current_user.courses.order("start_date DESC").limit(params[:limit]).offset(params[:offset]) + current_user.guest_courses.order("start_date DESC").limit(params[:limit]).offset(params[:offset])).map do|c|
			{
				"end_date"=>c.end_date,"id"=>c.id,"importing"=>c.importing,"image_url"=>c.image_url,"name"=>c.name,"short_name"=>c.short_name,"start_date"=>c.start_date,
				"user_id"=>c.user_id,"ended"=>c.ended,"duration"=>c.duration, "teacher_enrollments"=> c.teacher_enrollments.map { |u| { "user" => { "name" => u.user.name ,
				"email" => u.user.email } } }
			}
		end
		@total = @total_student > @total_teacher ? @total_student : @total_teacher
		render json: {:total => @total, :teacher_courses => teacher_courses, :student_courses => student_courses}
	end  

	def current_courses
		email = current_user.email.split('@')[1]
		if current_user.has_role?('Administrator')
			teacher_courses = Course.select([:start_date, :end_date, :name, :short_name, :id]).where("end_date > ?", Time.now)
		elsif current_user.is_school_administrator?
			email = UsersRole.where(:user_id => current_user.id, :role_id => 9)[0].admin_school_domain
			teacher_courses = Course.includes([:user,:teachers]).select([:start_date, :end_date, :name, :short_name, :id,:user_id]).select{|c| ( c.teachers.select{|t| t.email.include?(email) }.size>0 ) && (c.end_date > Date.today) }
		else
			teacher_courses=current_user.subjects_to_teach.where("end_date > ?", Time.now)
		end
		student_courses=current_user.courses.where("end_date > ?", Time.now)
		guest_courses  =current_user.guest_courses.where("end_date > ?", Time.now)
		render json: {:teacher_courses => teacher_courses, :student_courses => (student_courses+ guest_courses) }
	end  

	def get_role
		# # 1 teacher, 2 student, 3 prof, 4 TA, 5 Admin, 6 preview, 7 guest
		role = @course.get_role_user(current_user)
		render :json => {:role => role}
	end

	def new
		@course = Course.new
		email= current_user.email.match(/(\w+\.\w+$)/)[1]
		if current_user.has_role?('Administrator')
			@import= Course.all
		elsif current_user.has_role?('School Administrator')
			user_role = UsersRole.where(:user_id => user.id, :role_id => 9)[0]
			if user_role
				email = user_role.admin_school_domain || nil
			end
			if email
				@import= Course.includes([:user,:teachers]).select{|c| ( c.teachers.select{|t| t.email.include?(email) }.size>0 ) }
			end
		else
			@import= current_user.subjects_to_teach
		end
		subdomains = current_user.get_subdomains(email)
		if subdomains.count == 0
			subdomains.push(email)
		end
		subdomains = subdomains.uniq
		zones=ActiveSupport::TimeZone.all.sort{|v1,v2| v2.formatted_offset <=> v1.formatted_offset}
		@timezones=[]
		zones.each do |v|
			@timezones << {:value => v.to_s, :name => v.name, :offset => v.utc_offset()/3600}
		end
		render json: {:course => @course, :importing => @import, :timezones => @timezones , :subdomains=>subdomains} 
	end

	def show
		@course = Course.find_by_id(params[:id])
		zones=ActiveSupport::TimeZone.all.sort{|v1,v2| v2.formatted_offset <=> v1.formatted_offset}
		@timezones=[]
		zones.each do |v|
			@timezones << {:value => v.to_s, :name => v.name, :offset => v.utc_offset()/3600}
		end
		teachers =[]
		@course.teacher_enrollments.each do |e|
			teachers<<{:id => e.user_id, :name => User.find(e.user_id).full_name, :role => e.role.name, :email => User.find(e.user_id).email}
		end
		course = @course.as_json
		course[:duration] = @course.duration
		render json: {course: course, timezones: @timezones, teachers: teachers}
	end

	def teachers
		@teachers=[]
		@course.teacher_enrollments.each do |e|
			teacher = e.user
			teacher_rec = {:id => teacher.id, :name => teacher.name, :last_name => teacher.last_name, :email => teacher.email, :role => e.role_id, :status => "", :owner => false, :email_discussion => e.email_discussion}
			if @course.user == teacher
				teacher_rec[:owner] = true
				teacher_rec[:status] = "Owner"
			end
			@teachers << teacher_rec
		end
		@teachers = @teachers.sort_by {|h| [h[:owner] ? 0 : 1,h[:id]]}

		@course.invitations.each do |e|
			invited_user = User.find_by_email(e.email)
			teacher_rec = {:email => e.email, :role => e.role_id, :status => 'Pending'}
			if invited_user
				teacher_rec[:name] = invited_user.name
				teacher_rec[:last_name] = invited_user.last_name
			end
			@teachers << teacher_rec
		end
		render json: {:data => @teachers}
	end  

	def get_selected_subdomains
		course_domain = @course.course_domains.pluck(:domain)
		domains = []
		selected_domain = {}
		if course_domain.count ==0
			selected_domain['All'] = true
		end
		course_domain.each{|d| selected_domain[d] =true }
		@course.teachers.each do |t|
			teacher_domain = current_user.get_subdomains(t.email.match(/(\w+\.\w+$)/)[1])
			if teacher_domain.count == 0
				domains.push(t.email.match(/(\w+\.\w+$)/)[1])
			else
				domains = domains + current_user.get_subdomains(t.email.match(/(\w+\.\w+$)/)[1])
			end
			domains = domains.uniq
		end
		render json: {:subdomains => domains , :selected_domain => selected_domain}		
	end  

	def set_selected_subdomains
		course = Course.find_by_id(params[:id])
		database_domain = course.course_domains.pluck(:domain)
		if params[:selected_subdomains]['All']
			course.course_domains.destroy_all
		else
			## loop params domain and add domains(values is true and is not in database) and remove(values is false and in the database)
			params[:selected_subdomains].each  do |domain,value|
				if value && !database_domain.include?(domain)
					course.course_domains.create(:domain => domain)
				elsif !value && database_domain.include?(domain)
					course.course_domains.destroy(course.course_domains.find_by_domain(domain))
				end
			end
			## loop on database domain and delete the domain that are not in params
			database_domain.each do |database_domain|
				if !(params[:selected_subdomains].include?(database_domain))
					course.course_domains.destroy(course.course_domains.find_by_domain(database_domain))
				end
			end
		end
		render json: {:subdomains => true }
	end

	def update_teacher
		#update_all doesn't call validations.
		email=params[:email].downcase
		user = User.find_by_email(email)
		Invitation.where(:email => email, :course_id => @course.id).update_all(:role_id => params[:role]) #invited only - not yet created an account
		if !user.nil?
			@course.teacher_enrollments.where(:user_id =>user.id).update_all(:role_id => params[:role], :email_discussion => params[:email_discussion])
		end
		render json: {:notice => [ I18n.t("groups.saved")]}
	end

	def update_student_duedate_email
		enrolled_student = Enrollment.where(:course_id => params[:id] , :user_id => current_user.id)
		enrolled_student.update_all(:email_due_date => params[:"email_due_date"])  unless enrolled_student.nil?
		render json: {}
  	end 

	def update_teacher_discussion_email
		enrolled_teacher = TeacherEnrollment.where(:course_id => params[:id] , :user_id => current_user.id)
		enrolled_teacher.update_all(:email_discussion => params[:"email_discussion"])  unless enrolled_teacher.nil?
		render json: {}
	end  

	def get_student_duedate_email
		enrolled_student = Enrollment.where(:course_id => params[:id] , :user_id => current_user.id).first
		due_date_check = false
		due_date_check = enrolled_student.email_due_date unless enrolled_student.nil?
		render json: {:email_due_date => due_date_check}
	end

	def save_teachers
		teacher = params[:new_teacher]
		@errors={:email => [], :role => []}
		@errors[:role]<<[  I18n.t("controller_msg.must_have_role")] if teacher.nil? || teacher[:role].nil?
		@errors[:email]<<[  I18n.t("courses.enter_valid_email")] if teacher.nil? || teacher[:email].nil?
		if !teacher.nil? && !teacher[:role].nil? && !teacher[:email].nil?
			enrollments = @course.teacher_enrollments
			this_teacher = User.find_by_email(teacher[:email].downcase)

			if this_teacher.nil?  || !enrollments.any?{|a| a.user_id == this_teacher.id}
				if !this_teacher.nil? && @course.get_role_user(this_teacher) == 2
					@errors[:email]<<[ I18n.t("controller_msg.student_cannot_be_ta")]
				else
					a = Invitation.create(:user_id => current_user.id, :course_id => @course.id, :role_id => teacher[:role], :email => teacher[:email])
					if !a.errors.empty?
						@errors[:email]<<a.errors.full_messages
					else
						UserMailer.delay.teacher_email(@course, teacher[:email], teacher[:role], I18n.locale)
					end
				end
			else
				@errors[:email] << [ I18n.t("controller_msg.already_enrolled_in_course") ]
			end
		end

		@errors[:email].flatten!.uniq! if !@errors[:email].empty?
		@errors[:role].flatten!.uniq! if !@errors[:role].empty?
		@errors.each{|k,v| @errors[k]=v.join(",")}
		@errors.delete_if { |k, v| v.empty? }
		if @errors.empty?
			render json: {:nothing => true, :notice => [ I18n.t("groups.saved") ]}
		else
			render json: {errors: @errors}, :status => :unprocessable_entity #422
		end
	end

	def delete_teacher
		email=params[:email]
		@errors=[]

		if ( email =~ Devise.email_regexp ) == nil
		 	@errors <<   I18n.t("courses.enter_valid_email")
		elsif User.find_by_email(email.downcase).nil? #invited only - not yet created an account
			Invitation.where(:email => email, :course_id => @course.id).destroy_all
		else
			Invitation.where(:email => email, :course_id => @course.id).destroy_all
			if(@course.user == User.find_by_email(email.downcase)) #course owner
				@errors<< I18n.t("controller_msg.cannot_delete_course_owner")
			else
				@course.teacher_enrollments.where(:user_id => User.find_by_email(email.downcase).id).destroy_all
			end
		end

		@errors.flatten!
		if @errors.empty?
			if User.find_by_email(email.downcase) == current_user
				render json: {:remove_your_self => true , :notice => [ I18n.t("controller_msg.teacher_successfully_removed")] }
			else
				render json: {:notice => [ I18n.t("controller_msg.teacher_successfully_removed")]}
			end
		else
			render json: {errors: @errors}, :status => 400
		end
	end  

	# def get_all_teachers
	# end  
	
	# def edit
	# end  

	def validate_course_angular
		params[:course].each do |key, value|
			@course[key]=value
		end
		if @course.valid?
			render json:{ :nothing => true }
		else
			render json: {errors:@course.errors.full_messages}, status: :unprocessable_entity
		end
	end  

	def update
		if @course.update_attributes(course_params)
			render json: {course:@course, :notice => [I18n.t("controller_msg.course_successfully_updated") ]}
		else
			render json: {errors:@course.errors}, status: :unprocessable_entity
		end		
	end  

	def destroy
		if @course.destroy
			render :json => {:notice => [I18n.t('controller_msg.course_successfully_deleted')]}
		else
			render :json => {:errors => [I18n.t('controller_msg.could_not_delete_course')]} , :status => 400
		end
  	end  

	def remove_student
		@student=User.find(params[:student])
		@student_name=@student.name
		if @course.correct_student(@student)  && @student.remove_student(@course.id)
			render json: {:deleted => true, :notice =>["#{@student_name} #{I18n.t('controller_msg.was_removed_from')} #{I18n.t('groups.course')}"]}
		else
			render json: {:deleted => false, :errors => [I18n.t("controller_msg.could_not_remove_from_course", {student: @student_name})]}, :status => 400
		end
	end  

	def unenroll
		@course = params[:id]
		@student=current_user
		@student_name=@student.name
		if @student.remove_student(@course)
			render json: {:deleted => true, :notice =>["#{@student_name} #{I18n.t('controller_msg.was_removed_from')} #{I18n.t('groups.course')}"]}
		else
			render json: {:deleted => false, :errors => [I18n.t("controller_msg.could_not_remove_from_course", {student: @student_name})]}, :status => 400
		end
	end

	def enrolled_students
		@students = @course.enrolled_students.select("users.*, LOWER(users.name)").order("LOWER(users.name)") #enrolled
		@students.each do |s|
			s[:full_name] = s.full_name
		end
		render json: @students
	end  

	# def send_email
	# end  

	# def send_batch_email
	# end  

	def send_batch_email_through
		students = params[:emails]
		students.each_slice(50).to_a.each do |m|
			UserMailer.delay.student_batch_email(@course,m, params[:subject],params[:message], @course.user.email, I18n.locale)#.deliver
		end
		render json: {:nothing => true, :notice => [ I18n.t("controller_msg.email_sent_shortly")]}		
	end  

	# def send_email_through
	# end  

	def send_system_announcement
			list_type = params[:list_type].to_i
			if(list_type == 1)
					users = User.where( id: TeacherEnrollment.all.map(&:user_id).uniq ).map{|u| u.email}
			elsif(list_type == 2)
					users = User.where( id: Enrollment.all.map(&:user_id).uniq ).map{|u| u.email}
			elsif(list_type == 3)
					users = User.select(:email).all.map{|u| u.email}
			else
					users = params[:emails]
			end
			users.each_slice(50).to_a.each do |user|
					UserMailer.delay.system_announcement(user, params[:subject], params[:message], params[:reply_to])
			end
			render json: {:nothing => true, :notice => [I18n.t("controller_msg.email_sent_shortly")]}
	end 

	def course_editor_angular
		groups = @course.groups.all
		groups.each do |g|
			g['items'] = g.get_all_items
			g['total_time'] = g.total_time
		end

		if current_user.has_role?("Preview")
			user =User.where("email = ? AND name='preview' ",current_user.email.split('@')[0]+'_preview@scalable-learning.com' ).first
			if !user.nil?
				enrolled = user.enrollments.first
				if enrolled
					if enrolled.course_id == params[:id].to_i
						user.destroy()
					end
				end
			end
		end
		course1 =  @course.as_json
		course1[:duration] = @course.duration
		render json: {:course => course1,  :groups => groups}
	end  

	# def course_copy_angular
	# end  
	
	# def get_group_items_angular
	# end 
	
	# def get_course_angular
	# end  

	def module_progress_angular
		@student_names=[]
		@course=Course.where(:id => params[:id]).includes(:groups => [{:online_quizzes => [:online_answers, :lecture]}, :quizzes, :lectures => :online_quizzes])[0]
		@students=@course.users.select("users.*, LOWER(users.name), LOWER(users.last_name)").order("LOWER(users.last_name) ").limit(params[:limit]).offset(params[:offset]).includes([{:free_online_quiz_grades => [:lecture, :online_quiz]}, {:online_quiz_grades => [:lecture, :online_quiz]}, {:lecture_views => :lecture}, {:quiz_statuses => :quiz}, :assignment_statuses])

		@matrix={}
		@late={}
		@students.each do |s|
			@matrix[s.id]=s.grades_angular_test(@course)  #returns for each module in the course, whether student finished r not and on time or not.
			s.status={}
			s.assignment_statuses.each do |stat|
				if stat.status == 1
					s.status[stat.group_id]="Finished on Time"
				elsif stat.status == 2
					s.status[stat.group_id]="Not Finished"
				end
			end
		end

		@mods=@course.groups.map{|m| m.name}
		@total= @course.users.size
		render json: {:module_status => @matrix, :late_modules => @late, :students => @students.to_json(:methods => [:status, :full_name]), :module_names => @mods, :total => @total}
	end  

	def get_total_chart_angular
		@course=Course.where(:id => params[:id]).includes({:online_quizzes => [:online_answers, :lecture]}, :quizzes)[0]
		@student_progress=[]
		@nonline_total=@course.online_quizzes.select{|f| f.graded && f.lecture.graded && (!f.online_answers.empty? || f.question_type=="Free Text Question")}.size
		@lectures_total =@course.lectures.select{|l|  ( l.graded && !l.duration.nil? ) }.size
	
		@n_total= @course.quizzes.select{|v| v.quiz_type=="quiz" and v.graded}.size    #where(:quiz_type => "quiz").count
		@students=@course.users.select("users.*, LOWER(users.name), LOWER(users.last_name)").order("LOWER(users.last_name)").includes([{:free_online_quiz_grades => :lecture} , {:online_quiz_grades => :lecture} , {:quiz_statuses => :quiz}])
		@total=@students.size

		@students.each_with_index do |s, index|

			@n_solved=s.quiz_statuses.select{|v| v.course_id==@course.id && v.status=="Submitted" && v.quiz.quiz_type=='quiz' && v.quiz.graded}.size
			@nonline=s.online_quiz_grades.select{|q| q.course_id == @course.id && q.lecture.graded && q.online_quiz.graded }.uniq{|u| u.online_quiz_id}.size + s.free_online_quiz_grades.select{|f| f.course_id == @course.id && f.lecture.graded && f.online_quiz.graded}.uniq{|u| u.online_quiz_id}.size
			@lectures_views = s.lecture_views.select{ |lec_view| lec_view.lecture.graded && ( lec_view.percent ==100 ) }.size

			if @n_solved.nil? || @n_total==0
				@result1=0
			else
				@result1=@n_solved.to_f/@n_total.to_f*100
			end

			if @lectures_total == 0
				@result3=0
			else
				@result3= ( (@nonline.to_f + @lectures_views.to_f )/ ( @nonline_total.to_f + @lectures_total.to_f ) )*100
			end

			@student_progress[index]=[s.full_name, @result1, @result3] #@result2
		end
		render :json => {:student_progress => @student_progress}		
	end  

	def enroll_to_course
		key = params[:unique_identifier]
		key = key.upcase if key.size==11
		@course = Course.find_by_unique_identifier(key) || Course.find_by_guest_unique_identifier(key)
		if @course.nil?
			render :json => {:errors => [I18n.t('controller_msg.course_does_not_exist')], course: @course}, :status => :unprocessable_entity
		elsif current_user.courses.include?(@course)
			render :json => {:errors => [I18n.t('controller_msg.already_enrolled')], course: @course}, :status => :unprocessable_entity
		elsif current_user.subjects_to_teach.include?(@course)
			render :json => {:errors => [I18n.t('controller_msg.already_enrolled')], course: @course}, :status => :unprocessable_entity
		elsif @course.disable_registration && @course.disable_registration < DateTime.now.to_date
			render :json => {:errors => [I18n.t('controller_msg.after_registration')], course: @course}, :status => :unprocessable_entity
		elsif (@course.course_domains.count !=0) && (@course.course_domains.select{|c|( current_user.email.include?(c.domain) )  }.size == 0)
			render :json => {:errors => [I18n.t('controller_msg.course_domain_not_included')], course: @course}, :status => :unprocessable_entity
		else
			if @course.unique_identifier == key
				@course.users<<current_user
			elsif @course.guest_unique_identifier == key
				@course.guest_enrollments.create(:user_id => current_user.id)
			end
			render :json => {:notice => [I18n.t('controller_msg.already_enrolled_in', course: @course.name )], course: @course}
		end		
	end  

	def courseware_angular
		course=Course.find(params[:id])
		course[:duration] = course.duration
		is_preview_user = current_user.is_preview?
		today = Time.now
		filteredItems = {}
		initalGroups = course.groups.includes(:lectures, :quizzes, :custom_links)
		if is_preview_user
			groups = initalGroups.select{|v|
				filteredItems[g.id] = {
					:lectures => g.lectures,
					:quizzes => g.quizzes,
					:custom_links => g.custom_links
				};
				v.lectures.size > 0 ||
				v.quizzes.size > 0 ||
				v.custom_links.size > 0
			}
		else
			groups =initalGroups.select{|g|
				filteredItems[g.id] = {
					:lectures => g.lectures.select{|l| l.appearance_time<=today || l.inclass = true},
					:quizzes => g.quizzes.select{ |q| q.appearance_time<=today},
					:custom_links => g.custom_links
				};
				g.appearance_time <= today &&
				(
					
					filteredItems[g.id][:lectures].size > 0 ||
					filteredItems[g.id][:quizzes].size > 0 ||
					filteredItems[g.id][:custom_links].size > 0
				)
			}
		end

		groups.sort!{|x,y| ( x.position and y.position ) ? x.position <=> y.position : ( x.position ? -1 : 1 )  }

		should_enter=true
		next_i=nil
		last_viewed_group = -1
		last_viewed_lecture = course.lecture_views.includes(:lecture).select{|lec_view| lec_view.user_id == current_user.id && lec_view.lecture.appearance_time <= today }.sort_by!(&:updated_at).last
		last_viewed_group_id = last_viewed_lecture.group_id if !last_viewed_lecture.nil?

		groups.each do |g|
			g.current_user= current_user
			g[:has_inclass] = false
			g[:has_distance_peer] = false
			all = (filteredItems[g.id][:lectures] + filteredItems[g.id][:quizzes] + filteredItems[g.id][:custom_links]).sort{|a,b| a.position <=> b.position}
			all.each do |q|
				q[:class_name]= q.class.name.downcase
				if q[:class_name] != 'customlink'
					q.current_user=current_user
					q[:done] = q.is_done
					if last_viewed_group_id == g.id && last_viewed_lecture.lecture_id == q.id  && !q[:done] && should_enter
						next_i = q
						should_enter = false
					end
					if q[:class_name] == 'lecture' && !g[:has_inclass]
						g[:has_inclass] = q.inclass
					end
					if q[:class_name] == 'lecture' && !g[:has_distance_peer]
						g[:has_distance_peer] = q.distance_peer
					end
				end
			end
			g[:items] = all
			g[:sub_items_size] = filteredItems[g.id][:lectures].size + filteredItems[g.id][:quizzes].size
			g[:total_time] = g.total_time
		end
		next_item={}
		if !next_i.nil?
			next_item[:module]= next_i.group_id
			next_item[:item] = {:id => next_i.id, :class_name => next_i.class.name.downcase}
		elsif groups.size > 0 && groups[0].items.size > 0 && groups[0].items[0][:class_name]!="customlink"
			next_item[:module] = groups[0].id
			next_item[:item] = {:id => groups[0].items[0].id, :class_name => groups[0].items[0][:class_name]}
		else
			next_item[:module] = -1
			next_item[:item] = -1
		end

		render json: {:course => course,  :groups => groups, :next_item => next_item}
  	end

	# def courseware
	# end  

	def export_csv
		@course.export_course(current_user)
		render :json => {:notice => ['Course wil be exported to CSV and sent to your Email']}
	end

	# def export_student_csv
	# end  

	# def export_for_transfer
	# end  

	def export_modules_progress
		@course=Course.where(:id => params[:id]).includes(:groups => [{:online_quizzes => [:online_answers, :lecture]}, :quizzes, :lectures => :online_quizzes])[0]
		@course.export_modules_progress(current_user)
		render :json => {:notice => ['Course progress wil be exported to CSV and sent to your Email']}
	end  

	private
		def course_params
			params.require(:course).permit(:description, :end_date, :name, :prerequisites, :short_name, :start_date, :user_ids, :user_id, :time_zone, :discussion_link, :importing,
					 :image_url ,:disable_registration )
		end
end

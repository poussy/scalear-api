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
		teacher_courses = teacher_courses.map do|c|
			{
				"end_date"=>c.end_date,"id"=>c.id,"importing"=>c.importing,"image_url"=>c.image_url,"name"=>c.name,"short_name"=>c.short_name,
				"start_date"=>c.start_date,"user_id"=>c.user_id,"ended"=>c.ended,"duration"=>c.duration,'enrollments'=>c.enrollments.size ,'lectures'=>c.lectures.size ,
				'quiz'=>c.quizzes.select{|q| q.quiz_type =='quiz'}.size ,'survey'=>c.quizzes.select{|q| q.quiz_type !='quiz'}.size,
				"teacher_enrollments"=> c.teacher_enrollments.map { |u| { "user" => { "name" => u.user.name , "email" => u.user.email } } }
			}
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

	# def show
	# end  

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

	# def update_student_duedate_email
	# end  

	def update_teacher_discussion_email
		enrolled_teacher = TeacherEnrollment.where(:course_id => params[:id] , :user_id => current_user.id)
		enrolled_teacher.update_all(:email_discussion => params[:"email_discussion"])  unless enrolled_teacher.nil?
		render json: {}
	end  

	# def get_student_duedate_email
	# end  

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

	# def destroy
	# end  

	def remove_student
		@student=User.find(params[:student])
		@student_name=@student.name
		if @course.correct_student(@student)  && @student.remove_student(@course.id)
			render json: {:deleted => true, :notice =>["#{@student_name} #{I18n.t('controller_msg.was_removed_from')} #{I18n.t('groups.course')}"]}
		else
			render json: {:deleted => false, :errors => [I18n.t("controller_msg.could_not_remove_from_course", {student: @student_name})]}, :status => 400
		end
	end  

	# def unenroll
	# end  

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

	# def send_system_announcement
	# end  

	def course_editor_angular
		groups = @course.groups.all
		groups.each do |g|
			g['items'] = g.items
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

	# def module_progress_angular
	# end  

	# def get_total_chart_angular
	# end  

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

	# def courseware_angular
	# end  

	# def courseware
	# end  

	# def export_csv
	# end  

	# def export_student_csv
	# end  

	# def export_for_transfer
	# end  

	# def export_modules_progress
	# end  


private

  def course_params
    params.require(:course).permit(:description, :end_date, :name, :prerequisites, :short_name, :start_date, :user_ids, :user_id, :time_zone, :discussion_link, :importing,
    			 :image_url ,:disable_registration )
  end
end

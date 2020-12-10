class UserMailer < ApplicationMailer

	$frontend_host = Rails.configuration.frontend_host

	def announcement_email(users, announcement, course, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@users = users
		@announcement = announcement
		@url  = "courses/#{course.id}"
		@course = course
		@reply_to= course.user.email
		mail(:bcc => users, :subject => "(#{@course.short_name}) Announcement", :from => "\"ScalableLearning\" <no-reply@scalable-learning.com>", :reply_to => @reply_to)
	end


	def weekly_update_statistics(users, statistics, platform)		
		@statistics = statistics
		@platform = platform
		mail(:to => users, :subject => "Weekly statistics ( #{Date.today.to_s(:long)} )", :from => "\"ScalableLearning\" <no-reply@scalable-learning.com>")
	end

	def teacher_email(course, email, role, locale)
		I18n.locale=locale
		@reply_to= course.user.email
		@inviter=course.user
		@role=role
		@course=course
		@from= "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@role_name= Role.find(@role).display_name

		mail(:to => email, :subject => "(#{course.short_name}) #{I18n.t("user_mailer.added_to_course")}", :from => @from, :reply_to => @reply_to)
	end	
	
	def student_batch_email(course,users, subject, message, teacher_email, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@message=message
		@course = course
		mail(:bcc => users, :subject => subject, :from => @from, :reply_to => teacher_email)
	end

	def technical_problem_email(url, user, problem, course, group, lecture, quiz, agent,problem_website_type,version)
		I18n.locale= 'en'
		@from =  "\"Scalable Learning\" <info@scalable-learning.com>"
		@course= Course.find_by_id(course) if course!=-1
		@lecture= Lecture.find_by_id(lecture) if lecture!=-1
		@quiz= Quiz.find_by_id(quiz) if quiz!=-1
		if group!=-1
			@group= Group.find_by_id(group)
		elsif lecture!=-1
			@group = @lecture.group
		elsif quiz!=-1
  			@group = @quiz.group
		end

		@problem= problem.force_encoding(::Encoding::UTF_8)
		@problem_type = problem_website_type.force_encoding(::Encoding::UTF_8)
		@user_name= user.name
		@user_email=user.email
		if @course && @course.is_student(user)
			zendesk_email = "student-support@scalear.zendesk.com"
		else
			zendesk_email = "teacher-support@scalear.zendesk.com"
		end
		@url=url
		@url[0] = ''
		@agent = agent
		@version =version
		@bcc= ["karim@novelari.com"]
		@to = [zendesk_email]
		@bcc= [""]
		@reply_to= user.email
		mail(:bcc => @bcc,:to => @to, :subject => "ScalableLearning Technical Problem: #{@problem_type}", :from => @from, :reply_to => @user_email)
	end

	def content_problem_email(url, user, problem, course, group, lecture, quiz , agent,version)
		I18n.locale= 'en'
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@course= Course.find_by_id(course) if course!=-1
		@lecture= Lecture.find_by_id(lecture) if lecture!=-1
		@quiz= Quiz.find_by_id(quiz) if quiz!=-1
		if group!=-1
			@group= Group.find_by_id(group)
		elsif lecture!=-1
			@group = @lecture.group
		elsif quiz!=-1
			@group = @quiz.group
		end

		@problem= problem.force_encoding(::Encoding::UTF_8)
		@user_name= user.name
		@user_email=user.email
		@agent = agent
		@version =version
		@url=url
		@url[0] = ''
		@bcc= ["karim@novelari.com"]
		@to= @course.teachers.pluck(:email)
		subject = "#{@course.short_name} Student help request "
		@reply_to= user.email
		mail(:bcc => @bcc,:to => @to, :subject => subject, :from => @from, :reply_to => @user_email)
	end

	def contact_us_email(url, user, comment, agent)
		I18n.locale= 'en'
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@comment= comment
		@user_name= user.name
		@user_email=user.email
		@url=url
		@url[0] = ''
		@agent = agent
		@to = ["teacher-support@scalear.zendesk.com"]
		mail(:to => @to, :subject => "ScalableLearning Homepage Contact Request", :from => @from, :reply_to => @user_email)
	end

	def survey_email(user,question,answer,survey,course,response, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@user= User.find(user)
		@user_name= @user.name
		@user_email= @user.email
		@question=question
		@answer=answer
		@response=response
		@survey=survey
		@course=course
		@reply_to=course.user.email
		mail(:to => @user_email , :subject => "(#{@course.short_name}) Response to your survey", :from => @from, :reply_to=> @reply_to)
	end
	def course_as_text_attachment_email(user, course, file_name, file_path, locale)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course
		attachments[file_name]= File.read(file_path)
		mail(:to => @user_email , :subject => "Exported Course "+course.name+","+course.start_date.to_s+" as Text", :from => @from)
	end
	def attachment_email(user, course, file_name, file_path, locale)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course
		attachments[file_name]= File.read(file_path)

		mail(:to => @user_email , :subject => "Exported File", :from => @from)
	end

	def many_attachment_email (user, course, files , locale)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course
		files.each do |file|
			attachments[file[:file_name]]= File.read(file[:path])
		end	
		
		mail(:to => @user_email , :subject => "Exported File", :from => @from)	
	end	
	def imscc_txt_attachment_email(user, course, file_name, file_imscc_path, file_txt_path,locale )
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course
		attachments[file_name+".imscc"]= File.read(file_imscc_path)
		attachments[file_name+".html"]= File.read(file_txt_path)
		mail(:to => @user_email , :subject => "Exported Course:"+course.name+", "+course.start_date.to_s, :from => @from)
	end 

	def imscc_attachment_email(user, course, file_name, file_path, locale, with_export_fbf)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course
		attachments[file_name]= File.read(file_path)
		
		if (with_export_fbf=='true')	
			@with_export_fbf = true
		end 

		mail(:to => @user_email , :subject => "Exported Course:"+course.name+", "+course.start_date.to_s+" as Canvas Package", :from => @from)
	end	
	def course_export_start(user, course, locale)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course

		mail(:to => @user_email , :subject => "Course export started", :from => @from)
	end 	
	def course_export_queued(user, course, locale)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@course = course

		mail(:to => @user_email , :subject => "Course export received", :from => @from)
	end 	
	def progress_days_late(user, file_name, file_path, locale,course)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		attachments[file_name]= File.read(file_path)
		@url_progress  = "courses/#{course.id}/progress"
		@course_short_name = "#{course.short_name}"
		@today = Date.today
		mail(:to => @user_email , :subject => "(#{course.short_name}) Exported progress data ", :from => @from)
	end

	def analytics_student_questions(user_email, file_name, file_path, locale,course)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
		@user_email= user_email
		attachments[file_name]= File.read(file_path)
		mail(:to => @user_email , :subject => "analytics_student_questions", :from => @from)
	end

	def discussion_reply_email(post_owner, comment_owner, course, group, lecture, post, comment, locale)
		I18n.locale=locale
		@from =  "\"ScalableLearning\" <no-reply@scalable-learning.com>"
		@post_owner = post_owner
		@comment_owner = comment_owner
		@post = post
		@comment = comment
		@url  = "courses/#{course.id}/modules/#{group.id}/courseware/lectures/#{lecture.id}?time=#{post.time}"
		@course = course
		@lecture = lecture
		@module = group
		mail(:to => @post_owner.email, :subject => "(#{@course.short_name}) Answer to your question in #{@module.name}", :from => @from,:reply_to => @comment_owner.email)		
	end

	def teacher_discussion_email(post_owner, teacher, course, group, lecture, post, locale)
		I18n.locale=locale
		@from =  "\"ScalableLearning\" <no-reply@scalable-learning.com>"
		@post_owner = post_owner
		@teacher = teacher
		@post = post
		item_id = 'disc_'+post.id.to_s+'a'+post.lecture_id.to_s
		@url  = "courses/#{course.id}/modules/#{group.id}/progress?item_id=#{item_id}"
		@url2  = "courses/#{course.id}/information"
		@course = course
		@lecture = lecture
		@module = group
		mail(:to => @teacher.email, :subject => "(#{course.short_name}) Student question in #{lecture.name}", :from => @from)
	end

	def password_changed_email(user,locale)
			@user = user
			@from =  "\"Scalable Learning\" <no-reply@scalable-learning.com>"
			mail(:to => @user.email, :subject => "Password changed", :from => @from)
	end

	def due_date_email(user , course , item , item_type ,locale)
		I18n.locale=locale
		@from =  "\"ScalableLearning\" <no-reply@scalable-learning.com>"
		@url_information  = "courses/#{course.id}/course_information"
		@url_dashboard = "dashboard"
		@course = course
		@item_type = item_type
		@item = item
		@day_time = item.due_date.in_time_zone(course.time_zone)
		@user = user
		mail(:to => user.email, :subject => "(#{@course.short_name}) #{item_type} due soon ", :from => @from)		
	end

	def system_announcement(user, subject, message, reply_to)
			@from =  "<info@scalable-learning.com>"
			@message = message
			mail(:bcc => user, :subject => subject, :from => @from, :reply_to => reply_to)
	end

	def course_end_date_email(user, course, locale)
		I18n.locale=locale
		@from =  "\"ScalableLearning \" <no-reply@scalable-learning.com>"
		@url_information  = "courses/#{course.id}/information"
		@url_dashboard = "courses/dashboard"
		@course = course
		@user = user
		mail(:to => user.email, :subject => "(#{course.short_name}) End of course", :from => @from)
	end

	def inactive_user(emails_batch)
		headers["X-SMTPAPI"] = { :to => emails_batch }.to_json
		@from =  "\"ScalableLearning \" <no-reply@scalable-learning.com>"
		#here 'to' is just a placeholder, real emails are sent via sendgrid api
		mail(:to => "info@scalable-learning.com", :subject => "Your inactive account will be psudonymized soon", :from => @from)
	end

	def anonymisation_report(mail_to, successes,failures)
		@successes = successes
		@failures = failures
		mail(:to =>mail_to, :subject => "anonymisation report")
	end

	def anonymisation_success(emails_batch)
		headers["X-SMTPAPI"] = { :to => emails_batch }.to_json
		@from =  "\"ScalableLearning \" <no-reply@scalable-learning.com>"
		#here 'to' is just a placeholder, real emails are sent via sendgrid api
		mail(:to => "info@scalable-learning.com", :subject => "Your account on ScalableLearning has been pseudonymized", :from => @from)
	end

	def video_events(user, file_name, file_path, locale, group_name, course_name)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <info@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		@group_name = group_name
		@course_name = course_name
		attachments[file_name]= File.read(file_path)

		mail(:to => @user_email , :subject => "(#{@course_name}) Exported video data from  #{group_name}", :from => @from)
	end
	

end
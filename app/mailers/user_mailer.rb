class UserMailer < ApplicationMailer

	# def welcome_email(user)
	# end

	def announcement_email(users, announcement, course, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@users = users
		@announcement = announcement
		@url  = "courses/#{course.id}"
		@course = course
		@reply_to= course.user.email
		mail(:bcc => users, :subject => "#{I18n.t('user_mailer.new_announcement')} - #{course.name}", :from => @from, :reply_to => @reply_to)
	end

	def teacher_email(course, email, role, locale)
		I18n.locale=locale
		@reply_to= course.user.email
		@inviter=course.user
		@role=role
		@course=course
		@from= "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@role_name= Role.find(@role).display_name

		mail(:to => email, :subject => I18n.t("user_mailer.added_to_course"), :from => @from, :reply_to => @reply_to)
	end	
	
	# def student_email(course,user, subject, message, teacher_email, locale)
	# end

	def student_batch_email(course,users, subject, message, teacher_email, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@message=message
		@course = course
		mail(:bcc => users, :subject => subject, :from => @from, :reply_to => teacher_email)
	end

	# def technical_problem_email(url, user, problem, course, group, lecture, quiz, agent,problem_website_type,version)
	# end

	# def content_problem_email(url, user, problem, course, group, lecture, quiz , agent,version)
	# end

	# def contact_us_email(url, user, comment, agent)
	# end

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
		mail(:to => @user_email , :subject => "#{t('response_to')} #{survey}", :from => @from)
	end

	def attachment_email(user, file_name, file_path, locale)
		# puts "in email mailer"
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <info@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		attachments[file_name]= File.read(file_path)
		# puts "file is "
		# puts file.inspect

		mail(:to => @user_email , :subject => "Exported File", :from => @from)
	end

	def progress_days_late(user, file_name, file_path, locale,course)
		I18n.locale=locale
		@from =  "\"Scalable Learning\" <info@scalable-learning.com>"
		@user_name= user.name
		@user_email= user.email
		attachments[file_name]= File.read(file_path)
		@url_progress  = "courses/#{course.id}/progress"
		@course_short_name = "#{course.short_name}"
		@today = Date.today
		mail(:to => @user_email , :subject => "Course Progress Export from #{course.short_name} (#{course.name})", :from => @from)
	end

	# def analytics_student_questions(user_email, file_name, file_path, locale,course)
	# end

	# def apology_email(user, course)
	# end

	def discussion_reply_email(post_owner, comment_owner, course, group, lecture, post, comment, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		# @user_email = user.email
		@post_owner = post_owner
		@comment_owner = comment_owner
		@post = post
		@comment = comment
		@url  = "courses/#{course.id}/modules/#{group.id}/courseware/lectures/#{lecture.id}?time=#{post.time}"
		@course = course
		@lecture = lecture
		@module = group
		mail(:to => @post_owner.email, :subject => "You've got an answer! (#{lecture.name})", :from => @from,:reply_to => @comment_owner.email)		
	end

	def teacher_discussion_email(post_owner, teacher, course, group, lecture, post, locale)
		I18n.locale=locale
		@from =  "\"ScalableLearning Question\" <no-reply@scalable-learning.com>"
		@post_owner = post_owner
		@teacher = teacher
		@post = post
		item_id = 'disc_'+post.id.to_s+'a'+post.lecture_id.to_s
		@url  = "courses/#{course.id}/modules/#{group.id}/progress?item_id=#{item_id}"
		@url2  = "courses/#{course.id}/information"
		@course = course
		@lecture = lecture
		@module = group
		mail(:to => @teacher.email, :subject => "Question in #{course.short_name}: #{lecture.name}", :from => @from)
	end

	# def password_changed_email(user,locale)
	# end

	# def due_date_email(user , course , group , group_type ,locale)
	# end

	# def system_announcement(user, subject, message, reply_to)
	# end

	# def course_end_date_email(user, course, locale)	
	# end

end
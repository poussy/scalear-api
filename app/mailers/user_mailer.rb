class UserMailer < ApplicationMailer
	def announcement_email(users, announcement, course, locale)
		I18n.locale=locale
		@from =  "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@users = users
		@announcement = announcement
		@url  = "courses/#{course.id}"
		@course = course
		@reply_to= course.user.email
		mail(:bcc => users, :subject => "#{t('user_mailer.new_announcement')} - #{course.name}", :from => @from, :reply_to => @reply_to)
	end

	def teacher_email(course, email, role, locale)
		I18n.locale=locale
		@reply_to= course.user.email
		@inviter=course.user
		@role=role
		@course=course
		@from= "\"#{course.short_name} - #{course.name}\" <info@scalable-learning.com>"
		@role_name= Role.find(@role).display_name

		mail(:to => email, :subject => t("user_mailer.added_to_course"), :from => @from, :reply_to => @reply_to)
	end	
end
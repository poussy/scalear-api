desc "This task is called by the Heroku scheduler add-on"
task :send_end_date_course_email => :environment do
	courses =  Course.where("end_date >= ? and end_date < ?", 7.day.from_now.midnight, 8.day.from_now.midnight )
	puts courses
	courses.each do |course|
		course.teachers.each do |user|
			UserMailer.course_end_date_email(user, course, I18n.locale).deliver
		end
	end
end

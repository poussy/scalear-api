desc "This task is called by the Heroku scheduler add-on"
task :send_due_date_email => :environment do
	events =  Event.where("end_at between ? and ?", 1.day.from_now.midnight, 2.day.from_now.midnight )
	courses = events.map{|event| event.course_id}
	enrolled = Enrollment.where(:course_id => courses, :email_due_date => true).includes(:user).group_by(&:course_id)

	events.each do |ev|
		enrolled[ev.course_id].each do |enroll|
			if ev.group_id.nil? && !ev.lecture_id.nil?
				lecture = ev.lecture
				if enroll.user.finished_lecture_test?(lecture)[0]  < 0
					UserMailer.due_date_email(enroll.user, ev.course, lecture , "Lecture" , I18n.locale).deliver
				end
			elsif ev.group_id.nil? && !ev.quiz_id.nil?
				quiz = ev.quiz
				if quiz.quiz_type=='quiz'
					if  enroll.user.finished_quiz_test?(quiz) < 0
					    UserMailer.due_date_email(enroll.user , ev.course, quiz , "Quiz" , I18n.locale).deliver
					end
				elsif q.quiz_type=='survey'
					if enroll.user.finished_survey_test?(quiz) < 0
					    UserMailer.due_date_email(enroll.user , ev.course, quiz , "Survey" , I18n.locale).deliver
					end
				end
			else
				group = ev.group
				if enroll.user.finished_group_test?(group) < 0
					UserMailer.due_date_email(enroll.user , ev.course ,group , "Module" , I18n.locale).deliver
				end
			end
		end
	end
end

namespace :db do
	desc "Get Weekly active statistics"
	task :weekly_active => :environment do |t, args|
	 	dev_null = Logger.new("/dev/null")
		Rails.logger = dev_null
		ActiveRecord::Base.logger = dev_null
		new_users = User.where("created_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		new_courses = Course.where("created_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		updated_users = User.where("updated_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		updated_courses = Course.where("updated_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		lec_views = LectureView.where("updated_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		quiz_solved = QuizGrade.where("updated_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		updated_note= VideoNote.where("updated_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		updated_confused= Confused.where("updated_at between ? and ?", 1.week.ago.midnight, DateTime.now.midnight)
		updated_modules = Group.where("updated_at between ? and ? ", 1.week.ago.midnight, DateTime.now.midnight)
		updated_lectures= Lecture.where("updated_at between ? and ? ", 1.week.ago.midnight, DateTime.now.midnight)
		updated_quizzes = Quiz.where("updated_at between ? and ? ", 1.week.ago.midnight, DateTime.now.midnight)
		updated_links = CustomLink.where("updated_at between ? and ? ", 1.week.ago.midnight, DateTime.now.midnight)
		announcements = Announcement.where("updated_at between ? and ? ", 1.week.ago.midnight, DateTime.now.midnight)

		new_students = new_users.select{|u| u.has_role?('Student')}.count
		new_teachers = new_users.count - new_students

		updated_students = updated_users.map{|u| u.id}
		student_lec_views = lec_views.map{|l| l.user_id}
		student_quiz_solved  = quiz_solved.map{|q| q.user_id}
		student_updated_note = updated_note.map{|n| n.user_id}
		student_updated_confused = updated_confused.map{|c| c.user_id}
		active_students = ( student_lec_views+ student_quiz_solved + student_updated_note + student_updated_confused).uniq.count

		# updated_teachers = updated_users.select{|u| !u.has_role?('student')}.map{|u| u.id}
		teacher_updated_modules = updated_modules.map{|g| g.course.user_id}
		teacher_updated_lectures= updated_lectures.map{|l| l.course.user_id}
		teacher_updated_quizzes = updated_quizzes.map{|q| q.course.user_id}
		teacher_updated_links = updated_links.map{|l| l.course.user_id}
		teacher_announcements = announcements.map{|a| a.user_id}
		active_teachers = (teacher_updated_modules + teacher_updated_lectures + teacher_updated_quizzes + teacher_updated_links + teacher_announcements).uniq.count

		active_users = active_teachers + active_students

		updated_courses = updated_courses.map{|c| c.id}
		course_lec_views = lec_views.map{|l| l.course_id}
		course_quiz_solved = quiz_solved.map{|q| q.answer.question.quiz.course_id }
		course_updated_note= updated_note.map{|n| n.lecture.course_id}
		course_updated_confused= updated_confused.map{|c| c.course_id}
		course_updated_modules = updated_modules.map{|g| g.course_id}
		course_updated_lectures= updated_lectures.map{|l| l.course_id}
		course_updated_quizzes = updated_quizzes.map{|q| q.course_id}
		course_updated_links = updated_links.map{|l| l.course_id}
		course_announcements = announcements.map{|a| a.course_id}
		active_courses = (updated_courses + course_lec_views + course_quiz_solved + course_updated_note + course_updated_confused + course_updated_modules + course_updated_lectures + course_updated_quizzes + course_updated_links + course_announcements).uniq.count

		p "#{new_users.count} new users (#{new_students} students, #{new_teachers} teachers)"
		p "#{active_users} active users (#{active_students} students, #{active_teachers} teachers)"
		p "#{new_courses.count} new courses"
		p "#{active_courses} active courses"
	end
end
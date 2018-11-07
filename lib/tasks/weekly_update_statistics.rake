namespace :db do
    desc "Get Weekly on mondays active statistics"  
        task :weekly_update_statistics, [:platform]=> [:environment] do |t, args|
        if Date.today.monday?   
            dev_null = Logger.new("/dev/null")
            Rails.logger = dev_null
            ActiveRecord::Base.logger = dev_null
            createdAt_last_week_query = "created_at between '#{1.week.ago.midnight}' and '#{DateTime.now.midnight}'"
            updatedAt_last_week_query = "updated_at between '#{1.week.ago.midnight}' and '#{DateTime.now.midnight}'"
         
            
            new_users = User.where(createdAt_last_week_query)
            new_courses = Course.where(createdAt_last_week_query)
            
            updated_users = User.where(updatedAt_last_week_query)
            updated_courses = Course.where(updatedAt_last_week_query)
            lec_views = LectureView.where(updatedAt_last_week_query)
            quiz_solved = QuizGrade.where(updatedAt_last_week_query)
            updated_note= VideoNote.where(updatedAt_last_week_query)
            updated_confused= Confused.where(updatedAt_last_week_query)
            
            updated_modules = Group.where(updatedAt_last_week_query)
            updated_lectures= Lecture.where(updatedAt_last_week_query)
            updated_quizzes = Quiz.where(updatedAt_last_week_query)
            updated_links = CustomLink.where(updatedAt_last_week_query)
            announcements = Announcement.where(updatedAt_last_week_query)

            student_lec_views = lec_views.map{|l| l.user_id}
            student_quiz_solved = quiz_solved.map{|q| q.user_id}
            student_updated_note = updated_note.map{|n| n.user_id}
            student_updated_confused = updated_confused.map{|c| c.user_id}
            active_students = ( student_lec_views+ student_quiz_solved + student_updated_note + student_updated_confused).uniq.count

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
       
            p "#{new_users.count} new users"
            p "#{active_users} active users (#{active_students} students, #{active_teachers} teachers)"
            p "#{new_courses.count} new courses"
            p "#{active_courses} active courses"

            statistics = "<pre>
            #{new_users.count} new users 
            #{active_users} active users (#{active_students} students, #{active_teachers} teachers) 
            #{new_courses.count} new courses 
            #{active_courses} active courses</pre>"

            users = ["poussy@novelari.com", "david.black-schaffer@it.uu.se", "sverker@sics.se"]

            UserMailer.weekly_update_statistics(users, statistics, args['platform']).deliver_now
        end
    end 
end
namespace :db do
    desc "Get active statistics"  
    task :generalized_statistics, [:domain,:year]=> [:environment] do |t, args|
        weeks=[]       
        start_day = Date.new(args[:year].to_i) 
        weeks<<start_day
        (1..53).each do |w|
            start_day+=1.week
            weeks<<start_day if start_day < Date.new(args[:year].to_i+1)              
        end      
        activity_per_week=[]
        cumulative_user_count = 0 
        weeks.each_with_index do |someDay,i| 
            this_week_activity = generate_activity_statistics(args[:domain],weeks[i],weeks[i+1])
            if this_week_activity
                cumulative_user_count += this_week_activity[4]
                this_week_activity[6] = cumulative_user_count
                activity_per_week << this_week_activity     
            end
        end
        send_statistics(activity_per_week,args[:year],args[:domain])
    end 

    def send_statistics(activity_per_week,year,domain)
        csv_files={}
        csv_files[:activty_statistics]= CSV.generate do |statistic|
            statistic<<["startAt",'active_teachers','active_students','active_courses','new_users','new_courses','accumulative_total_users']
            activity_per_week.each do |week| 
                statistic<<week if week
            end                     
        end

        file_name = domain+"_weekly_activity_"+year.to_s+".zip"
        t = Tempfile.new(file_name)
        Zip::ZipOutputStream.open(t.path) do |z|
                csv_files.each do |key,value|
                        z.put_next_entry("#{key}.csv")
                        z.write(value)
                end
        end
        UserMailer.attachment_email(User.new(name:"poussy",email:"poussy@novelari.com"),Course.last, file_name, t.path, I18n.locale).deliver_now
        t.close    
    end 

    def generate_activity_statistics(domain ,startAt ,endAt)
        if !startAt.nil? & !endAt.nil? & !domain.nil?
            dev_null = Logger.new("/dev/null")
            Rails.logger = dev_null
            ActiveRecord::Base.logger = dev_null

            createdAt_last_week_query = "created_at between '#{startAt}' and '#{endAt}'"
            updatedAt_last_week_query = "updated_at between '#{startAt}' and '#{endAt}'"
            domain_users = "users.email like '%#{domain}%'"
            
            new_users = User.where(createdAt_last_week_query).where(domain_users)
            new_courses = Course.joins(:users).where("courses.created_at between '#{startAt}' and '#{endAt}'").where(domain_users)
            domain_users_ids = User.where(domain_users).pluck(:id)
            domain_courses_ids = Course.where('user_id in (?)',domain_users_ids).pluck(:id)
            id_in = 'id in (?)'
            user_id_in = 'user_id in (?)'
            course_id_in = 'course_id in (?)'

            updated_users = User.where(updatedAt_last_week_query).where(id_in,domain_users_ids)
            updated_courses = Course.where(updatedAt_last_week_query).where(user_id_in,domain_users_ids)
            lec_views = LectureView.where(updatedAt_last_week_query).where(user_id_in,domain_users_ids)
            quiz_solved = QuizGrade.where(updatedAt_last_week_query).where(user_id_in,domain_users_ids)
            updated_note= VideoNote.where(updatedAt_last_week_query).where(user_id_in,domain_users_ids)
            updated_confused= Confused.where(updatedAt_last_week_query).where(user_id_in,domain_users_ids)
            
            updated_modules = Group.where(updatedAt_last_week_query).where(course_id_in,domain_courses_ids)
            updated_lectures= Lecture.where(updatedAt_last_week_query).where(course_id_in,domain_courses_ids)
            updated_quizzes = Quiz.where(updatedAt_last_week_query).where(course_id_in,domain_courses_ids)
            updated_links = CustomLink.where(updatedAt_last_week_query).where(course_id_in,domain_courses_ids)
            announcements = Announcement.where(updatedAt_last_week_query).where(course_id_in,domain_courses_ids)

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
            
            p "#{startAt} week begining"
            p "#{active_students} students"
            p "#{active_teachers} teachers"
            p "#{active_courses} active courses"
            p "#{new_users.count} new users"
            p "#{new_courses.count} new courses"
            
            return [startAt,active_teachers,active_students,active_courses,new_users.count,new_courses.count]
        end
    end
end
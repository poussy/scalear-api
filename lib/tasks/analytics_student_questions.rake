desc "This task is called by the Heroku scheduler add-on"

# - Student questions
# - Teacher replies to student questions
# - Student replies to student questions
# - Questions chosen for in-class review
# - Total number of students in the class
# - Total number of modules
# - Total number of videos
# - Total number of quizzes (video and other)
# - Quizzes chosen for in-class review
# - In-class peer instruction quizzes chosen for in-class review

task :analytics_student_questions => :environment do
	p 'begin'
	courses = Course.includes([:user,:teachers])
	courses_ids = courses.map{|c| c.id}
    total_students_course = Enrollment.where(:course_id => courses_ids).group('course_id').count()
    total_teachers_course = TeacherEnrollment.where(:course_id => courses_ids).group('course_id').count()

    total_teachers = TeacherEnrollment.where(:course_id => courses_ids).group_by{|a| a.course_id}
    total_teachers.each{|course_id,teacher_list| total_teachers[course_id] = teacher_list.map{|teacher| teacher.user_id}}

    total_students = Enrollment.where(:course_id => courses_ids).group_by{|a| a.course_id}
    total_students.each{|course_id,student_list| total_students[course_id] = student_list.map{|student| student.user_id}}

    questions ={'inclass_review_show_questions' => {},'questions_count' => {}, 'comments_user_id'=> {}, 'teacher_replies' => {} ,'students_replies' =>{}}

    courses_ids.in_groups_of(50 ,false) do |course_ids|
      part_question = Forum::Post.get("analytics_student_questions", { :course_ids => course_ids })
      questions["inclass_review_show_questions"] = questions["inclass_review_show_questions"].merge(part_question['inclass_review_show_questions'])
      questions["questions_count"] = questions["questions_count"].merge(part_question['questions_count'])      
      questions["comments_user_id"] = questions["comments_user_id"].merge(part_question['comments_user_id'])
    end

    questions["comments_user_id"].each do |course_id, comment_users|
      teachers_count = comment_users.map(&:to_i).count{|x| (total_teachers[course_id.to_i]||[]).include?(x)}
      students_count = comment_users.map(&:to_i).count{|x| (total_students[course_id.to_i]||[]).include?(x)}
      questions['teacher_replies'][course_id] = teachers_count
      questions['students_replies'][course_id] = students_count
    end

    total_group_lec_views_by_course = LectureView.joins(:lecture).where("lecture_views.course_id IN (?)", courses_ids).group('lecture_views.course_id, lecture_views.lecture_id').select('lecture_views.lecture_id, lecture_views.course_id , ( (SUM(percent)/100) * (SUM(duration)/count(*)) ) as views ').group_by(&:course_id)
    modules_count_by_course = Group.where("course_id IN (?)", courses_ids).group(:course_id).count
    videos_count_by_course = Lecture.where("course_id IN (?)", courses_ids).group(:course_id).count
    quizzes_count_by_course = Quiz.where("course_id IN (?)", courses_ids).group(:course_id).count
    
	normal_online_quiz_count_by_course = OnlineQuiz.includes(:lecture).joins(:lecture).where('lectures.inclass != ? and online_quizzes.course_id IN (?)',true,courses_ids ).group('online_quizzes.course_id').count
	review_normal_online_quiz_count_by_course =  OnlineQuiz.includes(:lecture).joins(:lecture).where('lectures.inclass != ? and online_quizzes.course_id IN (?) and hide = ?',true,courses_ids,false ).group('online_quizzes.course_id').count
	inclass_online_quiz_count_by_course = OnlineQuiz.includes(:lecture).joins(:lecture).where('lectures.inclass = ? and online_quizzes.course_id IN (?)',true,courses_ids ).group('online_quizzes.course_id').count
	review_inclass_online_quiz_count_by_course =  OnlineQuiz.includes(:lecture).joins(:lecture).where('lectures.inclass = ? and online_quizzes.course_id IN (?) and hide = ?',true,courses_ids,false ).group('online_quizzes.course_id').count

	questions_quiz_count_by_course = Question.includes(:quiz).joins(:quiz).where('question_type != ? and quizzes.course_id IN (?)','header',courses_ids ).group('quizzes.course_id').count
	review_questions_quiz_count_by_course = Question.includes(:quiz).joins(:quiz).where('question_type != ? and quizzes.course_id IN (?) and show = ?','header',courses_ids, true ).group('quizzes.course_id').count

    p 'csv_file' 
    csv_file=CSV.generate do |csv_course|
      csv_course << ["short_name", "start_date", "end_date", "teachers","students","modules","video","quiz",
      				 "normal_online_quiz_count","review_normal_online_quiz_count","inclass_online_quiz_count","review_inclass_online_quiz_count",
      				 "questions_quiz_count","review_questions_quiz_count_by_course","discussions_count","inclass_review_show_discussion","teacher_replies",
      				 "students_replies","total_view"]
	    courses.each do |course|
	    	total_seconds = (total_group_lec_views_by_course[course.id].map{|l| l.views.to_i}.sum rescue 0)
			seconds = total_seconds % 60
			minutes = (total_seconds / 60) % 60
			hours = total_seconds / (60 * 60)
			time = format("%02d:%02d:%02d", hours, minutes, seconds)

	    	csv_course << [course.short_name, course.start_date, course.end_date, (total_teachers_course[course.id] || 0), (total_students_course[course.id] || 0),
	    				(modules_count_by_course[course.id] || 0), (videos_count_by_course[course.id] || 0), (quizzes_count_by_course[course.id] || 0),
	    				(normal_online_quiz_count_by_course[course.id] || 0),(review_normal_online_quiz_count_by_course[course.id] || 0),
	    				(inclass_online_quiz_count_by_course[course.id] || 0),(review_inclass_online_quiz_count_by_course[course.id] || 0),
	    				(questions_quiz_count_by_course[course.id.to_s] || 0), (review_questions_quiz_count_by_course[course.id.to_s]||0),
	    				(questions['questions_count'][course.id.to_s] || 0), (questions['inclass_review_show_questions'][course.id.to_s] || 0),
	    				(questions['teacher_replies'][course.id.to_s] || 0), (questions['students_replies'][course.id.to_s] || 0) , time]
	    end
    end

    file_name = "analytics_student_questions.zip"
    t = Tempfile.new(file_name)
    csv_file_name = "analytics_student_questions.csv"

    Zip::ZipOutputStream.open(t.path) do |z|
     z.put_next_entry(csv_file_name)
     z.write(csv_file)
    end
    UserMailer.analytics_student_questions('ahossam@novelari.com', file_name, t.path, I18n.locale,self).deliver
    t.close
end
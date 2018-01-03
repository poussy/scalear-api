require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@student1 = users(:student1)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@group1 = groups(:group1)
		@group2 = groups(:group2)
		@group3 = groups(:group3)
		
		## teacher in course 3
		@user3 = users(:user3)
		@user3.roles << Role.find(1)
		@course3 = courses(:course3)
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

		@group3_course1 = groups(:group3_course1)
		@assignment_statuses_course1 =  assignment_statuses(:assignment_statuses_course1)

		@student = users(:student_in_course3)

	end

	test "Validate abilities for user1" do
		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Group)
		assert ability1.can?(:destroy, @group1)
		assert ability1.cannot?(:destroy, @group2)
		assert ability1.can?(:get_module_summary, @group1)
	end
	
	test "Validate abilities for user2" do
		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Group)

		assert ability2.cannot?(:destroy, @group1)
		assert ability2.can?(:destroy, @group2)

		assert ability2.can?(:get_module_summary, @group2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:get_module_charts_angular, @group1)
		assert ability2.can?(:get_module_charts_angular, @group2)
	end

	test "create group" do

		groups_count = @course3.groups.count
		last_position = @course3.groups.last_created_record.position
		
		post '/en/courses/3/groups/new_module_angular', headers: @user3.create_new_auth_token
		
		@course3.reload
		
		assert_equal @course3.groups.count, groups_count + 1

		new_group = @course3.groups.last_created_record

		assert_equal new_group.name, "New Module"
		assert_equal new_group.position, last_position+1
		## course start_date is in the past
		assert_equal new_group.appearance_time, Time.zone.now.midnight.beginning_of_hour
		assert_equal new_group.due_date, Time.zone.now.midnight.beginning_of_hour + 1.week

	end

	test "group appearance_date should be like course start_date if it is in the future" do
		## course start_date is in the future
		course = Course.find(3)
		course.update_attributes(start_date: Time.zone.now + 2.day, end_date: Time.zone.now + 3.day)
		
		post '/en/courses/3/groups/new_module_angular', headers: @user3.create_new_auth_token
		
		new_group = @course3.groups.last_created_record

		assert_equal new_group.appearance_time, course.start_date.midnight.beginning_of_hour 
		assert_equal new_group.due_date,  new_group.appearance_time + 1.week
	end
	

	test "update groups action should update group" do
		user = users(:user1)
		##give user administrator role
		user.roles << Role.find(5)
		group = groups(:group3)

		assert_equal group.graded, false
		
		put '/en/courses/3/groups/3/', params: {group: {graded: true}}, headers: user.create_new_auth_token
		
		group.reload

		assert_equal group.graded, true
	end

	
	test "user should be able only to update a group in a course he is a teacher in" do

		@course3.teacher_enrollments.find_by(user_id: 3).destroy

		put '/en/courses/3/groups/3/', params: {group: {graded: true}}, headers: @user3.create_new_auth_token

		assert_response :forbidden
		
		## here we assign the user a teacher to that course
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
		
		put '/en/courses/3/groups/3/', params: {group: {graded: true}}, headers: @user3.create_new_auth_token

		assert_response :success
		
	end
	
	test "user should be able delete a group in a course he is a teacher in" do

		@course3.teacher_enrollments.find_by(user_id: 3).destroy

		delete '/en/courses/3/groups/3/', headers: @user3.create_new_auth_token

		assert_response :forbidden
		
		## here we assign the user a teacher to that course
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
		
		delete '/en/courses/3/groups/3/', headers: @user3.create_new_auth_token

		assert_response :success
		
	end

	test "sort action should sort groups" do

		assert_equal @course3.groups.find(3).position, 3
		assert_equal @course3.groups.find(4).position, 1
		assert_equal @course3.groups.find(5).position, 2
		
		post '/en/courses/3/groups/sort', params: {group:[{id: 3, course_id: 3},{id: 4, course_id: 3},{id: 5, course_id: 3}]},headers: @user3.create_new_auth_token
		
		assert_equal @course3.groups.find(3).position, 1
		assert_equal @course3.groups.find(4).position, 2
		assert_equal @course3.groups.find(5).position, 3
		
	end

	test "should create new link" do

		group = groups(:group3)

		assert_equal group.custom_links.count, 2

		post '/en/courses/3/groups/3/new_link_angular', headers: @user3.create_new_auth_token

		assert_equal group.custom_links.count, 3
		
	end

	test "should copy/paste group" do
	
		post '/en/courses/3/groups/module_copy', params: {module_id: 3}, headers: @user3.create_new_auth_token

		group_from = Group.find(3)
		new_group = Group.last

		assert group_from.name == new_group.name

		new_group.lectures.each_with_index do |new_lecture, i|
			assert_equal group_from.lectures[i].name, new_lecture.name
			assert_equal group_from.lectures[i].url, new_lecture.url
			assert_equal group_from.lectures[i].duration, new_lecture.duration
		end

		new_group.quizzes.each_with_index do |new_quiz, i|
			assert_equal group_from.quizzes[i].name, new_quiz.name
			assert_equal group_from.quizzes[i].retries, new_quiz.retries
			assert_equal group_from.quizzes[i].required, new_quiz.required
			assert_equal group_from.quizzes[i].graded, new_quiz.graded
		end
		
		new_group.custom_links.each_with_index do |new_link, i|
			assert_equal group_from.custom_links[i].name, new_link.name
			assert_equal group_from.custom_links[i].url, new_link.url
		end
	end

	test "statistics should return array of confuseds and really_confused" do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		confuseds = {
			[0, 10.0, 0]=>[10.0, "http://www.youtube.com/watch?v=xGcG4cp2yzY"], 
			[0, 13.0, 1]=>[13.0, "http://www.youtube.com/watch?v=xGcG4cp2yzY"], 
			[0, 30.0, 2]=>[30.0, "http://www.youtube.com/watch?v=xGcG4cp2yzY"]
		}
		confuseds_chart = Confused.get_rounded_time_module confuseds

		really_confuseds = {[0, 50.0, 0]=>[50.0, "http://www.youtube.com/watch?v=xGcG4cp2yzY"]}
		really_confuseds_chart = Confused.get_rounded_time_module really_confuseds
		assert_equal decode_json_response_body["confused"], confuseds_chart
		assert_equal decode_json_response_body["really_confused"], really_confuseds_chart
		
	end

	test "statistics should return array of backs " do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token
		backs = {[0, 50.0, 0]=>[50.0, "http://www.youtube.com/watch?v=xGcG4cp2yzY"]}
		backs_chart = VideoEvent.get_rounded_time_module backs
		assert_equal decode_json_response_body["back"], backs_chart

		## from_time - to_time must be >= 15
		VideoEvent.find(1).update(to_time: 20)
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		# assert_equal decode_json_response_body["back"], []
	end

	test "statistics should return array of pauses " do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		pauses = {[0, 60.0, 0]=>[60.0, "http://www.youtube.com/watch?v=xGcG4cp2yzY"]}
		pauses_chart = VideoEvent.get_rounded_time_module pauses
		assert_equal decode_json_response_body["pauses"], pauses_chart

	end

	test "statistics should return width, time_list, min, max and lecture_names " do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		## total time of lectures in group
		assert_equal decode_json_response_body["width"], 390

		assert_equal decode_json_response_body["time_list"], {"240.0"=>"http://www.youtube.com/watch?v=xGcG4cp2yzY", "390.0"=>"http://www.youtube.com/watch?v=xGcGdfrty"}
		
		assert_equal decode_json_response_body["lecture_names"], [[240.0, "lecture3"], [150.0, "lecture4"]]

		assert_equal decode_json_response_body["min"], Time.zone.parse(Time.seconds_to_time(0)).to_i
		duration = 390
		assert_equal decode_json_response_body["max"], Time.zone.parse(Time.seconds_to_time(duration)).floor(15.seconds).to_i

	end
	
	test "throw not_found error if no group found" do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/2/get_student_statistics_angular', headers: @user3.create_new_auth_token

		assert_equal decode_json_response_body["errors"], ["Record Not Found"]
	end
	

	test 'validate change_status_angular status from 1 to 2' do
		assert_equal @assignment_statuses_course1.status , 1
		url = '/en/courses/'+ @course1.id.to_s+'/groups/'+@group3_course1.id.to_s+'/change_status_angular'
		post url, params: {status:2 , user_id: @student1.id.to_s} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['success'] , true
		assert_equal resp['notice'][0] , 'Status successfully changed'
		assert_equal @assignment_statuses_course1.reload.status , 2
	end	
	test 'validate change_status_angular status 0 and check in the databsae the assignment_statuses got destroyed' do
		assert_equal AssignmentStatus.count , 1
		url = '/en/courses/'+ @course1.id.to_s+'/groups/'+@group3_course1.id.to_s+'/change_status_angular'
		post url, params: {status:0 , user_id: @student1.id.to_s} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['success'] , true
		assert_equal resp['notice'][0] , 'Status successfully changed'
		assert_equal AssignmentStatus.count , 0
	end	
	test 'validate change_status_angular status ' do
		@assignment_statuses_course1.destroy 
		assert_equal AssignmentStatus.count , 0
		
		url = '/en/courses/'+ @course1.id.to_s+'/groups/'+@group3_course1.id.to_s+'/change_status_angular'
		post url, params: {status:1 , user_id: @student1.id.to_s} ,headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_equal resp['success'] , true
		assert_equal resp['notice'][0] , 'Status successfully changed'
		assert_equal AssignmentStatus.count , 1
	end	


	test 'validate validate_group_angular method ' do
		url = '/en/courses/'+@course1.id.to_s+'/groups/'+@group3_course1.id.to_s+'/validate_group_angular'
		put  url , params: {group: { name:'toto' } } ,headers: @user1.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['nothing'] , true
	end
	test 'validate validate_group_angular method and respone 422 for title is empty' do
		url = '/en/courses/'+@course1.id.to_s+'/groups/'+@group3_course1.id.to_s+'/validate_group_angular'
		put  url , params: {group: { name:'' }} ,headers: @user1.create_new_auth_token 
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors'][0] , "Name can't be blank"
	end

	test 'validate get_group_statistics method ' do
		url = '/en/courses/'+'3'+'/groups/'+'3'+'/get_group_statistics'
		get  url , params: {group: { name:'' }} ,headers: @user3.create_new_auth_token 
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['items'].count , 5
		assert_equal resp['total_questions'] , 10
		assert_equal resp['total_quiz_questions'] , 6
		assert_equal resp['total_survey_questions'] , 0
		assert_equal resp['total_lectures'] , 2 
		assert_equal resp['total_quizzes'] , 1 
		assert_equal resp['total_surveys'] , 0
		assert_equal resp['total_links'] , 2 
	end

	test "get_online_quiz_summary" do
		get "/en/courses/3/groups/3/get_online_quiz_summary", headers: @student.create_new_auth_token

		group = decode_json_response_body["module"]

		assert_equal group["duration"], 390
		assert_equal group["quiz_count"], 11
		assert_equal group["survey_count"], 0
		assert_equal group["total_finished_duration"], 72 	# lecture 3: 240 * 30%
		assert_equal group["module_percentage"], 690 # lecture durations + 300 (quiz)
		assert_equal group["finished_all_quiz_count"], 2 #  online quizzes and normal quizzes 
		assert_equal group["finished_all_survey_count"], 0
		assert_equal group["online_quiz_count"], 16 # online_quizzes + questions in normal quizzes
		assert_equal group["remaining_duration"], 318 # 390 - 72
		assert_equal group["remaining_quiz"], 9
		assert_equal group["remaining_survey"], 0

		module_completion = group["module_completion"]

		assert_equal module_completion.size, 3 # 2 lectures + 1 quiz : quiz:1, lectures: 3,4
		
		# quizz
		quiz = module_completion[0]
		assert_equal quiz["id"], 1
		assert_equal quiz["item_name"], "quiz1"
		assert_equal quiz["duration"].round(), 43 # quiz duration(300)/module_percentage(690)*99
		assert_equal quiz["status"], "not_done"
		assert_equal quiz["percent_finished"], 0
		assert_equal quiz["type"], "quiz"
		# questions in quiz
		question = quiz["online_quizzes"][0] # here questions are named online_quizzes

		assert_equal question["quiz_name"], "<p class=\\\"medium-editor-p\\\">ocq</p>" #question.content
		assert_equal question["data"], ["self_never_tried"]
		assert_equal question["type"], "survey"

		#lecture
		lecture = module_completion[1]
		assert_equal lecture["id"], 3
		assert_equal lecture["item_name"], "lecture3"
		assert_equal lecture["duration"].round(), 34 # lecture duration(240)/module_percentage(690)*99
		assert_equal lecture["status"], "not_done"
		assert_equal lecture["percent_finished"], 30
		assert_equal lecture["type"], "lecture"
		#online quizzes in lecture
		online_quiz = lecture["online_quizzes"][0] 

		assert_equal online_quiz["quiz_name"], "New Quiz"
		assert_equal online_quiz["data"], ["self_correct_first_try"]
		assert_equal online_quiz["type"], "quiz"

	end

	test "should return result according to attempts and correctness" do
		# correct from second time
		OnlineQuizGrade.where(online_quiz_id:1).first.update_attributes(:attempt=>2)
		
		get "/en/courses/3/groups/3/get_online_quiz_summary", headers: @student.create_new_auth_token
		module_completion = decode_json_response_body["module"]["module_completion"]
		online_quiz = module_completion[1]["online_quizzes"][0]
		assert_equal online_quiz["data"], ["self_tried_correct_finally"]
		
		#not correct and 2 tries
		grade = OnlineQuizGrade.where(online_quiz_id:1).first
		grade.update_attributes(:attempt=>1, :grade=>0)
		#another grade
		grade.dup.update_attributes(:attempt=>2, :grade=>0, id:2)
		
		get "/en/courses/3/groups/3/get_online_quiz_summary", headers: @student.create_new_auth_token
		
		module_completion = decode_json_response_body["module"]["module_completion"]
		online_quiz = module_completion[1]["online_quizzes"][0]
		assert_equal online_quiz["data"], ["self_tried_not_correct_finally"]
	end

	test "get_online_quiz_summary survey"do 
		# quiz survey
		Quiz.find(1).update_attributes(:quiz_type=>"survey")
		get "/en/courses/3/groups/3/get_online_quiz_summary", headers: @student.create_new_auth_token
		
		module_completion = decode_json_response_body["module"]["module_completion"]
		quiz = module_completion[0]
		assert_equal quiz["type"], "survey"
		#online quiz survey
		OnlineQuiz.find(1).update_attributes(:quiz_type=>"survey")
		get "/en/courses/3/groups/3/get_online_quiz_summary", headers: @student.create_new_auth_token
		module_completion = decode_json_response_body["module"]["module_completion"]
		online_quiz = module_completion[1]["online_quizzes"][0]
		assert_equal online_quiz["type"], "survey"
		#online quiz survey never tried
		OnlineQuizGrade.where(online_quiz_id:1).destroy_all
		get "/en/courses/3/groups/3/get_online_quiz_summary", headers: @student.create_new_auth_token
		module_completion = decode_json_response_body["module"]["module_completion"]
		online_quiz = module_completion[1]["online_quizzes"][0]
		assert_equal online_quiz["data"], ["self_never_tried"]

	end

	test 'module completion' do
		get '/en/courses/3/groups/3/get_all_items_progress_angular', headers: @user3.create_new_auth_token

		assert_equal decode_json_response_body['total'], 5
		students_ids = Enrollment.where(course_id: 3).map{|e|e.user_id}
		students = User.where(id: students_ids)
		(JSON.parse decode_json_response_body['students']).each_with_index do |k,v|
			assert_equal k['name'], students[v]['name']
			
		end
				
		assert_equal decode_json_response_body['lecture_names'], @group3.get_sub_items.map{|m|m.name}
		assert_equal decode_json_response_body['lecture_status'], {
			"6"=>[[1, -1, 0, 6, 0, 0, 0, 2], [3, -1, 0, 0, 2, 10, 30, 1], [4, -1, 0, 0, 0, 0, 0, 1]], 
			"7"=>[[1, -1, 0, 6, 0, 0, 0, 2], [3, -1, 0, 0, 0, 10, 0, 1], [4, -1, 0, 0, 0, 0,0, 1]], 
			"8"=>[[1, -1, 0, 6, 0, 0, 0, 2], [3, -1, 0, 0, 0, 10, 0, 1], [4, -1, 0, 0, 0, 0, 0, 1]], 
			"9"=>[[1, -1, 0, 6, 0, 0, 0, 2], [3, -1, 0, 0, 0, 10, 0, 1], [4, -1, 0, 0, 0, 0, 0, 1]], 
			"10"=>[[1, -1, 0, 6, 0, 0, 0, 2], [3, -1, 0, 0, 0, 10, 0, 1], [4, -1, 0, 0, 0, 0, 0, 1]]}
		
	end

	test 'module review get_online_quiz_summary' do
		get '/en/courses/3/groups/3/get_online_quiz_summary', headers: @user3.create_new_auth_token

		online_quizzes_and_questions = decode_json_response_body["module"]["online_quiz"]

		assert_equal online_quizzes_and_questions.size, 16 # total online_quizzes in lectures and questions in normal quizzes
		question = online_quizzes_and_questions[0]["1"]
		assert_equal question["lecture_name"], "quiz1" #question.quiz.name
		assert_equal question["quiz_name"], "<p class=\\\"medium-editor-p\\\">ocq</p>" #question.content
		assert_equal question["type"], "quiz"

		online_quiz = online_quizzes_and_questions[6]["1"]
		assert_equal online_quiz["lecture_name"], "lecture3"
		assert_equal online_quiz["quiz_name"], "New Quiz"
		assert_equal online_quiz["type"], "quiz"

	end

	test 'module review online_quiz data of non free_text_question' do
		#correct_quiz
		QuizGrade.create(user_id: 7, quiz_id: 1, question_id: 1, answer_id: 5, grade: 1 )
		#not_correct_quiz
		QuizGrade.create(user_id: 8, quiz_id: 1, question_id: 1, answer_id: 4, grade: 0)

		#correct_first_try already in fixtures
		#not__correct_first_try
		OnlineQuizGrade.create(user_id: 8,course_id: 3, lecture_id: 3, group_id: 3, attempt: 1, online_quiz_id: 1, online_answer_id: 7, grade: 0, review_vote: true )
		#not_correct_many_tries
		OnlineQuizGrade.create(user_id: 9,course_id: 3, lecture_id: 3, group_id: 3, attempt: 2, online_quiz_id: 1, online_answer_id: 7, grade: 0 )
		#tried correct finally
		OnlineQuizGrade.create(user_id: 10,course_id: 3, lecture_id: 3, group_id: 3, attempt: 2, online_quiz_id: 1, online_answer_id: 7, grade: 1 )
		

		get '/en/courses/3/groups/3/get_online_quiz_summary', headers: @user3.create_new_auth_token

		question = decode_json_response_body["module"]["online_quiz"][0]["1"]

		assert_equal question["data"]["correct_quiz"], 1
		assert_equal question["data"]["not_correct_quiz"], 1
		assert_equal question["data"]["never_tried"], 3

		online_quiz = decode_json_response_body["module"]["online_quiz"][6]["1"]

		assert_equal online_quiz["data"]["correct_first_try"], 1
		assert_equal online_quiz["data"]["tried_correct_finally"], 1
		assert_equal online_quiz["data"]["not_correct_first_try"], 1
		assert_equal online_quiz["data"]["not_correct_many_tries"], 1
		assert_equal online_quiz["data"]["never_tried"], 1
		assert_equal online_quiz["data"]["review_vote"], 1

	end

	test 'module review online_quiz data for free_text_question' do
		#correct_quiz
		QuizGrade.create(user_id: 7, quiz_id: 1, question_id: 6, answer_id: 8, grade: 3 )
		#not_correct_quiz
		QuizGrade.create(user_id: 8, quiz_id: 1, question_id: 6, answer_id: 8, grade: 1)
		#not checked
		QuizGrade.create(user_id: 9, quiz_id: 1, question_id: 6, answer_id: 8, grade: 0)

		#not_correct_first_try
		OnlineQuizGrade.create(user_id: 6,course_id: 3, lecture_id: 3, group_id: 3, attempt: 1, online_quiz_id: 10, online_answer_id: 7, grade: 1 )
		
		#correct_first_try
		OnlineQuizGrade.create(user_id: 8,course_id: 3, lecture_id: 3, group_id: 3, attempt: 1, online_quiz_id: 10, online_answer_id: 7, grade: 3 )
		#tried_correct_finally
		OnlineQuizGrade.create(user_id: 7,course_id: 3, lecture_id: 3, group_id: 3, attempt: 3, online_quiz_id: 10, online_answer_id: 7, grade: 3 )
		#not_correct_many_tries
		OnlineQuizGrade.create(user_id: 9,course_id: 3, lecture_id: 3, group_id: 3, attempt: 2, online_quiz_id: 10, online_answer_id: 7, grade: 1 )
		#not_checked
		OnlineQuizGrade.create(user_id: 10,course_id: 3, lecture_id: 3, group_id: 3, attempt: 2, online_quiz_id: 10, online_answer_id: 7, grade: 0 )
		

		get '/en/courses/3/groups/3/get_online_quiz_summary', headers: @user3.create_new_auth_token

		question = decode_json_response_body["module"]["online_quiz"][5]["6"]

		assert_equal question["data"]["correct_quiz"], 1
		assert_equal question["data"]["not_correct_quiz"], 1
		assert_equal question["data"]["not_checked"], 1
		assert_equal question["data"]["never_tried"], 2

		online_quiz = decode_json_response_body["module"]["online_quiz"][15]["10"]

		assert_equal online_quiz["data"]["correct_first_try"], 1
		assert_equal online_quiz["data"]["tried_correct_finally"], 1
		assert_equal online_quiz["data"]["not_correct_first_try"], 1
		assert_equal online_quiz["data"]["not_correct_many_tries"], 1
		assert_equal online_quiz["data"]["not_checked"], 1
		assert_equal online_quiz["data"]["never_tried"], 0
		assert_equal online_quiz["data"]["review_vote"], 0

	end

	test "get_online_quiz_summary for survey questions" do

		## normal quiz
		Quiz.create(id: 50,name: 'quiz2', retries: 0, group_id: 3 , course_id: 3, appearance_time_module: false, appearance_time: '2017-9-10', 
			due_date_module: false, due_date: '2017-10-9', position: 16, required: true, required_module: false, graded: true, graded_module: false, visible: true, 
			quiz_type: 'survey', instructions: "Please fill the survey")
		
		Question.create(id: 55,quiz_id: 50, content: "<p class=\"medium-editor-p\">mcq survey</p>", question_type: "MCQ", show: true, position: 1, student_show: true, match_type: nil)
		
		QuizGrade.create(user_id: 6, quiz_id: 50, question_id: 55, answer_id: 1, grade: 0.0)

		## online_quiz

		OnlineQuiz.create(id: 56, course_id: 3, group_id: 3, lecture_id: 3, question_type: "OCQ", quiz_type: "survey", inclass: false, graded: false, start_time: 170, time: 170, end_time: 170, question: "Survey1", display_text: true)
		OnlineQuizGrade.create(user_id: 6, course_id: 3, group_id: 3, lecture_id:3, online_quiz_id: 56, online_answer_id: 1, grade: 0.0)
		
		
		get '/en/courses/3/groups/3/get_online_quiz_summary', headers: @user3.create_new_auth_token

		
 		assert_equal decode_json_response_body["module"]["online_quiz"][17]["55"]["quiz_name"], "<p class=\"medium-editor-p\">mcq survey</p>"
 		assert_equal decode_json_response_body["module"]["online_quiz"][17]["55"]["data"], {"survey_solved"=>1, "never_tried"=>4}

 		assert_equal decode_json_response_body["module"]["online_quiz"][16]["56"]["quiz_name"], "Survey1"
 		assert_equal decode_json_response_body["module"]["online_quiz"][16]["56"]["data"], {"survey_solved"=>1, "never_tried"=>4}


	end

	test "get_quiz_charts" do

		QuizStatus.create(user_id: 7, quiz_id: 1, course_id: 3, status: "Submitted", group_id: 3)
		QuizStatus.create(user_id: 8, quiz_id: 1, course_id: 3, status: "Submitted", group_id: 3)

		QuizGrade.create(user_id: 7, quiz_id: 1, question_id: 1, answer_id: 4, grade: 1 )
		QuizGrade.create(user_id: 8, quiz_id: 1, question_id: 3, answer_id: 5, grade: 1)


		FreeAnswer.create(user_id: 7, quiz_id:1, question_id: 3, answer: "answer to free text")

		FreeAnswer.create(user_id: 7, quiz_id: 1, question_id: 4, answer: ["<p class=\"medium-editor-p\">ans1</p>", "<p class=\"medium-editor-p\">ans2</p>"], 
			response: "", hide: true, grade: 1, student_hide: false,)

		get '/en/courses/3/groups/3/get_quiz_charts', headers: @user3.create_new_auth_token

		quiz = decode_json_response_body["quizzes"]["1"]

		assert_equal quiz["meta"]["id"], Quiz.find(1).id
		assert_equal quiz["questions"].size, Question.where(quiz_id:1).size
		assert_equal quiz["free_question"].size, Question.where(quiz_id: 1, question_type: "Free Text Question").size
		assert_equal quiz["free_question"]["3"]["answers"][0]["answer"],"answer to free text"
		
		assert_equal quiz["charts"].size, Question.where(quiz_id: 1, question_type: "Free Text Question").size
		#ocq
		assert_equal quiz["charts"]["1"],  {"answers"=>
          	{"4"=>[1, false, "<p class=\"medium-editor-p\">a1</p>"],
           "5"=>[1, true, "<p class=\"medium-editor-p\">a2</p>"]}}
		#mcq
		assert_equal quiz["charts"]["2"],  {"answers"=>
          {"1"=>[0, false, "<p class=\\\"medium-editor-p\\\">a1</p>"],
           "2"=>[0, true, "<p class=\\\"medium-editor-p\\\">a2</p>"]}}
		# drag
		assert_equal quiz["charts"]["4"],  {"answers"=>
         	 {"<p class=\"medium-editor-p\">ans1</p>"=>
				[1,true,"<p class=\"medium-editor-p\">ans1</p> in correct place"],
			"<p class=\"medium-editor-p\">ans2</p>"=>
				[1,true,"<p class=\"medium-editor-p\">ans2</p> in correct place"]}}
		
	end

	test "get_survey_charts" do

		Quiz.find(1).update_attributes(:quiz_type=>"survey")

		QuizStatus.create(user_id: 7, quiz_id: 1, course_id: 3, status: "Saved", group_id: 3)
		QuizStatus.create(user_id: 8, quiz_id: 1, course_id: 3, status: "Saved", group_id: 3)

		QuizGrade.create(user_id: 7, quiz_id: 1, question_id: 1, answer_id: 4, grade: 1 )
		QuizGrade.create(user_id: 8, quiz_id: 1, question_id: 3, answer_id: 5, grade: 1)


		FreeAnswer.create(user_id: 7, quiz_id:1, question_id: 3, answer: "answer to free text")

		FreeAnswer.create(user_id: 7, quiz_id: 1, question_id: 4, answer: ["<p class=\"medium-editor-p\">ans1</p>", "<p class=\"medium-editor-p\">ans2</p>"], 
			response: "", hide: true, grade: 1, student_hide: false,)

		
		get '/en/courses/3/groups/3/get_survey_charts', headers: @user3.create_new_auth_token

		quiz = decode_json_response_body["surveys"]["1"]
		
		assert_equal quiz["meta"]["id"], Quiz.find(1).id
		assert_equal quiz["questions"].size, Question.where(quiz_id:1).size
		assert_equal quiz["free_question"].size, Question.where(quiz_id: 1, question_type: "Free Text Question").size
		assert_equal quiz["free_question"]["3"]["answers"][0]["answer"],"answer to free text"
		assert_equal quiz["charts"].size, Question.where(quiz_id: 1, question_type: "Free Text Question").size
		#ocq
		assert_equal quiz["charts"]["1"], {
			"show"=>false, "student_show"=>true, "answers"=>{
				"4"=>[1, "<p class=\"medium-editor-p\">a1</p>"], 
				"5"=>[1, "<p class=\"medium-editor-p\">a2</p>"]}, 
			"title"=>"<p class=\\\"medium-editor-p\\\">ocq</p>"}
		#mcq
		assert_equal quiz["charts"]["2"],  {
			"show"=>false, "student_show"=>true, "answers"=>{
				"1"=>[0, "<p class=\\\"medium-editor-p\\\">a1</p>"], 
				"2"=>[0, "<p class=\\\"medium-editor-p\\\">a2</p>"]}, 
			"title"=>"<p class=\\\"medium-editor-p\\\">q1</p>"}

	end
	test "get_module_progress" do 
		get '/en/courses/3/groups/3/get_module_progress', headers: @user3.create_new_auth_token

		assert_equal decode_json_response_body["lectures"]["3"]["confused"],  [[0.0, {"count"=>2, "show"=>true}], [30.0, {"count"=>1, "show"=>true}]]
		assert_equal decode_json_response_body["lectures"]["3"]["really_confused"], [[45.0, {"count"=>1, "show"=>true}]]
		assert_equal decode_json_response_body["lectures"]["3"]["discussion"], []
		assert_equal decode_json_response_body["review_question_count"], 4
		
		charts = decode_json_response_body["lectures"]["3"]["charts"]
		# ocq & mcq
		assert_equal charts["1"],  [20.0,{
			"title"=>"New Quiz",
			"type"=>"OCQ",
			"quiz_type"=>"Quiz",
			"review"=>0,
			"hide"=>true,
			"id"=>1,
			"answers"=>	{
				"6"=>[1, "green", "answer1", 0],
				"7"=>[0, "orange", "answer2", 0],
				"8"=>[4, "gray", "Never tried"]}}]
		# drag
		assert_equal charts["5"], [50.0,{
			"title"=>"DRAG Quiz",
			"type"=>"drag",
			"quiz_type"=>"Quiz",
			"review"=>0,
			"hide"=>true,
			"id"=>5,
			"answers"=>
				{"11"=>[0, "green", "<p class=\"medium-editor-p\">answer1</p>", 0],
				"12"=>[0, "green", "<p class=\"medium-editor-p\">answer2</p>", 0],
				"13"=>[0, "green", "<p class=\"medium-editor-p\">answer3</p>", 0],
				"14"=>[5, "gray", "Never tried"]}}]

		# free text questions
		free_questions = decode_json_response_body["lectures"]["3"]["free_question"]
		assert_equal free_questions.size, 4
		assert ["2","3","9","10"].all? {|s| free_questions.key? s}
		assert_equal free_questions["2"], [50.0, {
			"review"=>0,
          	"title"=>"New Quiz",
			"answers"=>
				[{"id"=>1,
					"user_id"=>6,
					"online_quiz_id"=>2,
					"online_answer"=>"answer1",
					"grade"=>0.0,
					"lecture_id"=>3,
					"group_id"=>3,
					"course_id"=>3,
					"response"=>"",
					"hide"=>true,
					"review_vote"=>false,
					"attempt"=>1,
					"created_at"=>"2017-06-12T02:00:00.000+02:00",
					"updated_at"=>"2017-06-12T02:00:00.000+02:00"}],
				"show"=>false,
				"id"=>2,
				"quiz_type"=>"Quiz"}]

		assert_equal decode_json_response_body["students_count"], Course.find(3).users.count
		
	end

	test "hide invideo quiz should toggle hide of selected quiz to true or false" do
		assert_changes 'OnlineQuiz.find(1).hide', from: true, to: false do
			post '/en/courses/3/groups/3/hide_invideo_quiz', params:{hide:false, quiz:1}, headers: @user3.create_new_auth_token
		end

		assert_changes 'OnlineQuiz.find(1).hide', from: false, to: true do
			post '/en/courses/3/groups/3/hide_invideo_quiz', params:{hide:true, quiz:1}, headers: @user3.create_new_auth_token
		end
	end
	
end
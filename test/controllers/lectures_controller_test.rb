require 'test_helper'

class LecturesControllerTest < ActionDispatch::IntegrationTest
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@group1 = groups(:group1)
		@group2 = groups(:group2)

		@lecture1 = lectures(:lecture1)
		@lecture2 = lectures(:lecture2)

		## @user3 is teacher in @course3 wich contains @group3
		@user3 = users(:user3)
		@user3.roles << Role.find(1)
		@course3 = courses(:course3)
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
		@group3 = @course3.groups.find(3)

		@student = users(:student_in_course3)
		@headers2 = @student.create_new_auth_token
		@headers2['content-type']="application/json"

		## necessary to send as json, so true and false wouldn't convert to strings
		@headers = @user3.create_new_auth_token
		@headers['content-type']="application/json"
	end

	test "Validate abilities for user1" do
		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Lecture)
		assert ability1.can?(:destroy, @lecture1)
		assert ability1.cannot?(:destroy, @lecture2)
		assert ability1.can?(:new_lecture_angular, @lecture1)
	end

	test "Validate abilities for user2" do
		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Lecture)

		assert ability2.cannot?(:destroy, @lecture1)
		assert ability2.can?(:destroy, @lecture2)

		assert ability2.can?(:new_lecture_angular, @lecture2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:new_quiz_angular, @lecture1)
		assert ability2.can?(:new_quiz_angular, @lecture2)
	end


	test "sort action should sort items" do

		assert_equal @group3.custom_links.find(1).position,1
		assert_equal @group3.custom_links.find(2).position,2
		assert_equal @group3.quizzes.find(1).position,3
		assert_equal @group3.lectures.find(3).position,4

		post '/en/courses/3/lectures/sort', params: {items:
			[
				{id: 1 , "class_name": "quiz"},{id: 1, class_name: "customlink"},
				{id: 2, class_name: "customlink"}, {id: 3, class_name: "lecture"}
			],
			group: 3}, headers: @user3.create_new_auth_token

		@group3.reload

		assert_equal @group3.custom_links.find(1).position,2
		assert_equal @group3.custom_links.find(2).position,3
		assert_equal @group3.quizzes.find(1).position,1
		assert_equal @group3.lectures.find(3).position,4

	end

	test "user should be able to add new lecture" do

		lectures_count = @group3.lectures.count

		get '/en/courses/3/lectures/new_lecture_angular', params: {distance_peer: false, group: 3, inclass: false}, headers: @headers

		@group3.reload

		assert_equal @group3.lectures.count, lectures_count+1

	end

	test "should be able to edit lecture" do

		lecture = lectures(:lecture3)

		assert lecture.required
		assert_equal lecture.appearance_time, '2017-9-8'
		assert lecture.due_date_module
		assert_equal lecture.due_date, '2017-10-8'
		assert_equal lecture.position, 4
		assert lecture.graded

			put '/en/courses/3/lectures/3', params:{:lecture => {required: false, appearance_time: '2017-10-6',appearance_time_module: false, due_date_module: false,
			due_date: '2017-10-7', position: 1, graded: false}}, headers: @user3.create_new_auth_token

		lecture.reload
		assert_not lecture.required
		assert_equal lecture.appearance_time, Time.zone.parse('2017-10-6')
		assert_not lecture.due_date_module
		assert_equal lecture.due_date, Time.zone.parse('2017-10-7')
		assert_equal lecture.position, 1
		assert_not lecture.graded

	end

	test "should be able to delete lecture" do

		assert @course3.lectures.where(id: 3).present?

			delete '/en/courses/3/lectures/3', headers: @user3.create_new_auth_token

		assert @course3.lectures.where(id: 3).empty?
	end

	test "should update graded, required, appearance_time and due_date according to parent module's" do

		lecture =lectures(:lecture3)

		assert lecture.required
		assert lecture.graded
		assert_equal lecture.appearance_time, '2017-9-8'
		assert_equal lecture.due_date, '2017-10-8'

		@inclass_session_count = InclassSession.count
		## parent module has required ==false and graded ==false
		put '/en/courses/3/lectures/3', params: {:lecture => {required_module: true, graded_module: true, appearance_time_module: true, due_date_module: true, inclass: true}}, headers: @headers, as: :json

		lecture.reload

		assert_not lecture.required
		assert_not lecture.graded
		assert_equal lecture.appearance_time, '2017-9-9'
		assert_equal lecture.due_date, '2017-10-9'
		assert lecture.inclass
		assert_equal InclassSession.count , (@inclass_session_count +  lecture.online_quizzes.count)
		@inclass_session_count = InclassSession.count
		put '/en/courses/3/lectures/3', params: {:lecture => { inclass: false}}, headers: @headers, as: :json
		assert_equal InclassSession.count , (@inclass_session_count -  lecture.online_quizzes.count)
	end

	test "should copy lecture to same group" do
		lecture =lectures(:lecture3)
		put '/en/courses/3/lectures/3', params: {:lecture => {required_module: true, graded_module: true, appearance_time_module: true, due_date_module: true, inclass: true}}, headers: @headers, as: :json
		@inclass_session_count = InclassSession.count
		@online_marker_count = OnlineMarker.count
		@event_count = Event.count


		group = Group.find(3)
		lectures_count = group.lectures.size

		post '/en/courses/3/lectures/lecture_copy', params: {lecture_id: 3, module_id: 3}, headers: @headers, as: :json

		assert_equal group.lectures.size, lectures_count + 1


		lecture_from = Lecture.find(3)
		new_lecture = Lecture.last

		assert_equal lecture_from.name, new_lecture.name
		assert_equal lecture_from.url, new_lecture.url
		## due_date and appearance_time is copied from parent group
		assert_equal group.due_date, new_lecture.due_date
		assert_equal group.appearance_time, new_lecture.appearance_time
		assert_equal InclassSession.count , (@inclass_session_count + lecture.online_quizzes.count)
		assert_equal Event.count , (@event_count + lecture.events.count)
		assert_equal OnlineMarker.count , (@online_marker_count + lecture.online_markers.count)

	end

	test "should copy lecture to other group" do

		group = Group.find(4)

		assert_equal group.lectures.size, 0

		post '/en/courses/3/lectures/lecture_copy', params: {lecture_id: 3, module_id: 4}, headers: @headers, as: :json

		group.reload
		assert_equal group.lectures.size, 1

		lecture_from = Lecture.find(3)
		new_lecture = Lecture.last

		assert_equal lecture_from.name, new_lecture.name
		assert_equal lecture_from.url, new_lecture.url
		## due_date and appearance_time is copied from parent group
		assert_equal group.due_date, new_lecture.due_date
		assert_equal group.appearance_time, new_lecture.appearance_time


	end

	test "should create online quiz" do
		lecture = lectures(:lecture3)
		initial_count =  lecture.online_quizzes.size

		get '/en/courses/3/lectures/3/new_quiz_angular', params:{end_time:28, inclass:false,ques_type:"OCQ",quiz_type:"survey",start_time:28,time:28}, headers: @headers

		lecture.reload
		assert_equal lecture.online_quizzes.size, initial_count+1

	end

	test "should create quiz with question according to quiz_type param" do
		lecture = lectures(:lecture3)

		get '/en/courses/3/lectures/3/new_quiz_angular', params:{end_time:28, inclass:false,ques_type:"OCQ",quiz_type:"survey",start_time:28,time:28}, headers: @headers
		lecture.reload
		assert_equal lecture.online_quizzes.last_created_record.question, "New Quiz"


		get '/en/courses/3/lectures/3/new_quiz_angular', params:{end_time:28, inclass:false,ques_type:"OCQ",quiz_type:"html_survey",start_time:28,time:28}, headers: @headers
		lecture.reload
		assert_equal lecture.online_quizzes.last_created_record.question, "New Quiz"

		get '/en/courses/3/lectures/3/new_quiz_angular', params:{end_time:28, inclass:false,ques_type:"OCQ",quiz_type:"invideo",start_time:28,time:28}, headers: @headers
		lecture.reload
		assert_equal lecture.online_quizzes.last_created_record.question, "New Quiz"
	end

	test "should create quiz with right params" do
		lecture = lectures(:lecture3)

		get '/en/courses/3/lectures/3/new_quiz_angular', params:{end_time:50, inclass:false, ques_type:"OCQ",quiz_type:"invideo",start_time:10,time:15}, headers: @headers

		lecture.reload

		assert_equal lecture.online_quizzes.last_created_record.question_type, "OCQ"
		assert_equal lecture.online_quizzes.last_created_record.quiz_type, "invideo"
		assert_equal lecture.online_quizzes.last_created_record.inclass, false
		assert_equal lecture.online_quizzes.last_created_record.start_time, 10
		assert_equal lecture.online_quizzes.last_created_record.time, 15
		assert_equal lecture.online_quizzes.last_created_record.end_time, 50

	end

	test "should add new_marker " do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/new_marker'
		post url , params: { marker: {time:15,duration:5,xcoor:0.5,ycoor:0.2,height:1.1,width:2.3}},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['marker']['time'] , 15.0
		assert_equal resp['marker']['duration'] , 5
		assert_equal resp['marker']['xcoor'] , 0.5
		assert_equal resp['marker']['ycoor'] , 0.2
		assert_equal resp['marker']['height'] , 1.1
		assert_equal resp['marker']['width'] , 2.3
	end

	test "should new_marker for invalid time" do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/new_marker'
		post url , params: { marker: {time:'aaa'}},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response 400
		assert_equal resp['errors']['time'][0] , "is not a number"
	end

	test 'validate validate_lecture_angular method ' do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/validate_lecture_angular'
		put  url , params: {lecture: { name:'toto' } } ,headers: @user1.create_new_auth_token
		assert_response :success
		resp =  JSON.parse response.body
		assert_equal resp['nothing'] , true
	end
	test 'validate validate_lecture_angular method and respone 422 for title is empty' do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/validate_lecture_angular'
		put  url , params: {lecture: { name:'' }} ,headers: @user1.create_new_auth_token
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors'][0] , "Name can't be blank"
	end
	test 'validate validate_lecture_angular method and respone 422' do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/validate_lecture_angular'
		put  url , params: {lecture: { due_date_module:false ,  due_date:DateTime.now + 3.months } } ,headers: @user1.create_new_auth_token
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors'][0] , "Due date must be before module due date"
	end
	test 'validate validate_lecture_angular method and respone 422 for retries is not position' do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/validate_lecture_angular'
		put  url , params: {lecture: { inclass:true , distance_peer:true  }} ,headers: @user1.create_new_auth_token
		assert_response 422
		resp =  JSON.parse response.body
		assert_equal resp['errors'].count , 1
		assert_equal resp['errors'][0] , "Distance peer must be inclass or distance peer"
	end

	test "should get_html_data_angular " do
		@html_ocq_online_quiz1 = online_quizzes(:html_ocq_online_quiz1)

		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/get_html_data_angular'
		get url , params: { quiz: @html_ocq_online_quiz1.id.to_s},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['answers'].count , 2
	end

	test "should get_html_data_angular after updating online_quizzes" do
		@html_ocq_online_quiz1 = online_quizzes(:html_ocq_online_quiz1)
		@html_ocq_online_answer_correct2 = online_answers(:html_ocq_online_answer_correct2)

		@html_ocq_online_answer_correct2.update_attribute(:online_quiz_id,4)
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/get_html_data_angular'
		get url , params: { quiz: @html_ocq_online_quiz1.id.to_s},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['answers'].count , 1
		@html_ocq_online_answer_correct2.update_attribute(:online_quiz_id,@html_ocq_online_quiz1.id)
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/get_html_data_angular'
		get url , params: { quiz: @html_ocq_online_quiz1.id.to_s},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['answers'].count , 2
	end

	test "should get_old_data_angular " do
		@ocq_online_quiz1 = online_quizzes(:ocq_online_quiz1)

		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/get_old_data_angular'
		get url , params: { quiz: @ocq_online_quiz1.id.to_s},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['answers'].count , 2
	end
	test "should get_old_data_angular after updating online_quizzes" do
		@ocq_online_quiz1 = online_quizzes(:ocq_online_quiz1)
		@ocq_online_answer_correct1 = online_answers(:ocq_online_answer_correct1)

		@ocq_online_answer_correct1.update_attribute(:online_quiz_id,4)
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/get_old_data_angular'
		get url , params: { quiz: @ocq_online_quiz1.id.to_s},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['answers'].count , 1
		@ocq_online_answer_correct1.update_attribute(:online_quiz_id,@ocq_online_quiz1.id)
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/get_old_data_angular'
		get url , params: { quiz: @ocq_online_quiz1.id.to_s},headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['answers'].count , 2
	end

	test "should save_answers_angular " do
		@ocq_online_quiz1 = online_quizzes(:ocq_online_quiz1)
		@ocq_online_answer_correct1 = online_answers(:ocq_online_answer_correct1)
		@ocq_online_answer2 = online_answers(:ocq_online_answer2)


		assert_equal @ocq_online_quiz1.online_answers.count , 2
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/save_answers_angular'
		post url , params: {online_quiz_id: @ocq_online_quiz1.id.to_s ,  "answer":[
			{id: @ocq_online_answer_correct1.id.to_s , online_quiz_id: @ocq_online_quiz1.id.to_s , "answer":"Answer 2","xcoor":0.344155844155844,"ycoor":0.188742921754339,"correct":false,"explanation":"",
				"width":0.0168831168831169,"height":0.0300230946882217,"pos":0,"sub_ycoor":0.0987429217543393,"sub_xcoor":0.344155844155844,
				"created_at":"2017-11-20T15:21:18.024Z","updated_at":"2017-11-22T18:17:09.075Z"},
			{"answer":"Answer 2","xcoor":0.344155844155844,"ycoor":0.188742921754339,"correct":false,"explanation":"",
				"width":0.0168831168831169,"height":0.0300230946882217,"pos":0,"sub_ycoor":0.0987429217543393,"sub_xcoor":0.344155844155844,
				"created_at":"2017-11-20T15:21:18.024Z","updated_at":"2017-11-22T18:17:09.075Z"},
			{"answer":"Answer 3","xcoor":0.391872278664732,"ycoor":0.437437332782549,"correct":true,"explanation":"",
				"width":0.0188679245283019,"height":0.0335051546391753,"pos":0,"sub_ycoor":0.347437332782549,"sub_xcoor":0.391872278664732,
				"created_at":"2017-11-22T18:17:09.083Z","updated_at":"2017-11-22T18:17:09.083Z"}],
			"quiz_title":"<p class=\"medium-editor-p\">ocq </p>"} ,headers: @user1.create_new_auth_token
		resp =  JSON.parse response.body
		assert_equal OnlineAnswer.where(id: @ocq_online_answer_correct1.id).count , 1
		assert_equal OnlineAnswer.where(id: @ocq_online_answer2.id).count , 0
		assert_response :success
		assert_equal @ocq_online_quiz1.online_answers.count , 3
		assert_equal resp['notice'] , "Quiz was successfully saved"
	end

	test "should update percent view if view is present with the highest percent" do
		post '/en/courses/3/lectures/3/update_percent_view', params: {percent:50}, headers: @headers2, as: :json
		assert_equal LectureView.where(lecture_id:3).first.percent, 50
		#now highest percent is 50
		post '/en/courses/3/lectures/3/update_percent_view', params: {percent:20}, headers: @headers2, as: :json
		assert_equal LectureView.where(lecture_id:3).first.percent, 50
	end

	test "should create percent view and set its percent if no view is present" do
		LectureView.where(lecture_id:3).destroy_all
		post '/en/courses/3/lectures/3/update_percent_view', params: {percent:20}, headers: @headers2, as: :json
		assert_equal LectureView.where(lecture_id:3).first.percent, 20
	end

	test "should set percent view to 100 if it is 5 seconds or less to end" do
		post '/en/courses/3/lectures/3/update_percent_view', params: {percent:98}, headers: @headers2, as: :json
		assert_equal LectureView.where(lecture_id:3).first.percent, 100
	end

	test "save_online should create new OnlineQuizGrade and respond with details" do
		# OCQ
		assert_difference 'OnlineQuizGrade.where(online_quiz_id:1,online_answer_id: 6, lecture_id: 3).size' do
			post '/en/courses/3/lectures/3/save_online', params: {quiz: 1, answer: 6, distance_peer:false, in_group: false}, headers: @headers2, as: :json
		end

		assert_equal decode_json_response_body['msg'], "Successfully Submitted"
		assert_equal decode_json_response_body['correct'], 1
		assert_equal decode_json_response_body['explanation'], ["explanation for answer1"]
		assert_equal decode_json_response_body['detailed_exp'], { "6"=> [true,"explanation for answer1"], "7"=> [false,"explanation for answer2"] }
		assert_equal decode_json_response_body['done'], ["3",3,false]

	end

	test "MCQ question's answers must be all right to be saved as grade = 1" do
		# MCQ correct answers are 8,10
		post '/en/courses/3/lectures/3/save_online', params: {quiz: 4, answer: [8,9], distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal OnlineQuizGrade.where(online_quiz_id:4, online_answer_id: 8).first.grade, 0
		assert_equal OnlineQuizGrade.where(online_quiz_id:4, online_answer_id: 9).first.grade, 0

		post '/en/courses/3/lectures/3/save_online', params: {quiz: 4, answer: [8,10], distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal OnlineQuizGrade.where(online_quiz_id:4, online_answer_id: 8).second.grade, 1
		assert_equal OnlineQuizGrade.where(online_quiz_id:4, online_answer_id: 10).first.grade, 1
		assert_equal OnlineQuizGrade.where(online_quiz_id:4, online_answer_id: 10).first.attempt, 2
	end

	test "drag question" do

		post '/en/courses/3/lectures/3/save_online', params: {
			quiz: 5,
			answer:{
				"11":"<p class=\"medium-editor-p\">answer3</p>",
				"12":"<p class=\"medium-editor-p\">answer2</p>",
				"13":"<p class=\"medium-editor-p\">answer1</p>"},
			distance_peer:false,
			in_group: false}, headers: @headers2, as: :json
		assert_equal decode_json_response_body['explanation'], ["item 1 incorrect here because....","correct because..","item 3 is incorrect because.."]
		assert_equal decode_json_response_body['detailed_exp'], {"11" => [false,"item 1 incorrect here because...."],"12"=>[true,"correct because.."],"13"=>[false,"item 3 is incorrect because.."]}
	end

	test "save_online should create new OnlineQuizGrade with right attempts" do

		assert_difference "OnlineQuizGrade.where(online_quiz_id:1,online_answer_id: 6, lecture_id: 3).last['attempt']", 2 do
			# first attempt
			post '/en/courses/3/lectures/3/save_online', params: {quiz: 1, answer: 7, distance_peer:false, in_group: false}, headers: @headers2, as: :json
			# second
			post '/en/courses/3/lectures/3/save_online', params: {quiz: 1, answer: 6, distance_peer:false, in_group: false}, headers: @headers2, as: :json

		end


	end

	test "free text should create quiz grade 0 if no answer was specified" do

		post '/en/courses/3/lectures/3/save_online', params: {quiz: 2, answer: "answer for free text", distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal FreeOnlineQuizGrade.where(online_quiz_id:2).first["grade"], 0
		assert_equal decode_json_response_body["explanation"], {"2"=>"<p class=\"medium-editor-p\">explanation free text</p>"}
	end

	test "free text should create quiz grade 1 if answer is right" do

		post '/en/courses/3/lectures/3/save_online', params: {quiz: 3, answer: "answer for free text", distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal FreeOnlineQuizGrade.where(online_quiz_id:3).first["grade"], 1
		assert_equal decode_json_response_body["explanation"], {"3"=>"<p class=\"medium-editor-p\">explanation free text</p>"}
	end
	##save_html questions
	test "save_html should create new OnlineQuizGrade and respond with details" do
		# OCQ
		post '/en/courses/3/lectures/3/save_html', params: {quiz: 6, answer: "14", distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal OnlineQuizGrade.where(online_quiz_id:6).size, 1

		assert_equal decode_json_response_body['msg'], "Successfully Submitted"
		assert_equal decode_json_response_body['correct'], 1
		assert_equal decode_json_response_body['explanation'], ["explanation for answer1"]
		assert_equal decode_json_response_body['detailed_exp'], { "14"=> [true,"explanation for answer1"], "15"=> [false,"explanation for answer2"] }
		assert_equal decode_json_response_body['done'], ["3",3,false]
	end

	test "MCQ question's answers must be all right to be saved as grade = 1 in save_html" do
		# MCQ correct answers are 8,10
		post '/en/courses/3/lectures/3/save_html', params: {quiz: 7, answer: {"16": true,"17": true}, distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal OnlineQuizGrade.where(online_quiz_id:7, online_answer_id: 16).first.grade, 0
		assert_equal OnlineQuizGrade.where(online_quiz_id:7, online_answer_id: 17).first.grade, 0

		post '/en/courses/3/lectures/3/save_html', params: {quiz: 7, answer: {"16": true,"18": true}, distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal OnlineQuizGrade.where(online_quiz_id:7, online_answer_id: 16).second.grade, 1
		assert_equal OnlineQuizGrade.where(online_quiz_id:7, online_answer_id: 18).first.grade, 1
		assert_equal OnlineQuizGrade.where(online_quiz_id:7, online_answer_id: 18).first.attempt, 2
	end

	test "html drag question correct" do

		post '/en/courses/3/lectures/3/save_html', params: {
			quiz: 8,
			answer: ["<p class=\"medium-editor-p\">answer1</p>","<p class=\"medium-editor-p\">answer2</p>"]}, headers: @headers2, as: :json

		assert_equal decode_json_response_body['correct'],true

		assert_equal decode_json_response_body['explanation'],{
			"8"=> {
				"<p class=\"medium-editor-p\">answer1</p>"=>"<p class='medium-editor-p'>explanation 1</p>",
				"<p class=\"medium-editor-p\">answer2</p>"=>"<p class='medium-editor-p'>explanation 2</p>"
			}
		}
	end

	test "html drag question incorrect should not return explanation" do

		post '/en/courses/3/lectures/3/save_html', params: {
			quiz: 8,
			answer: ["<p class=\"medium-editor-p\">answer2</p>","<p class=\"medium-editor-p\">answer1</p>"]}, headers: @headers2, as: :json

		assert_equal decode_json_response_body['correct'],false

		assert decode_json_response_body['explanation'].empty?
	end

	test "save_html should create new OnlineQuizGrade with right attempts" do
		# first attempt
		post '/en/courses/3/lectures/3/save_html', params: {quiz: 6, answer: "15", distance_peer:false, in_group: false}, headers: @headers2, as: :json
		# second
		post '/en/courses/3/lectures/3/save_html', params: {quiz: 6, answer: "14", distance_peer:false, in_group: false}, headers: @headers2, as: :json

		assert_equal OnlineQuizGrade.where(online_quiz_id:6,online_answer_id: 14, lecture_id: 3).first['attempt'], 2
	end

	test "html free text should create quiz grade 0 if no answer was specified" do

		post '/en/courses/3/lectures/3/save_html', params: {quiz: 9, answer: "answer for free text", distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal FreeOnlineQuizGrade.where(online_quiz_id:9).first["grade"], 0
		assert_equal decode_json_response_body["explanation"], {"9"=>"<p class=\"medium-editor-p\">explanation free text</p>"}
	end

	test "html free text should create quiz grade 1 if answer is right" do

		post '/en/courses/3/lectures/3/save_html', params: {quiz: 10, answer: "answer free text", distance_peer:false, in_group: false}, headers: @headers2, as: :json
		assert_equal FreeOnlineQuizGrade.where(online_quiz_id:10).first["grade"], 3
		assert_equal decode_json_response_body["explanation"], {"10"=>"<p class=\"medium-editor-p\">explanation free text</p>"}
	end

	test "should create video_event with right parameters" do
		post '/en/courses/3/lectures/3/log_video_event', params: {"event":"play","from_time":161.776062,"in_quiz":false,"speed":1,"volume":0.8,"fullscreen":false}, headers: @headers2, as: :json
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["event_type"], 1
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["from_time"], 161.776062
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["speed"], 1
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["volume"], 0.8

		post '/en/courses/3/lectures/3/log_video_event', params: {"event":"pause","from_time":161.776062,"in_quiz":false,"speed":1,"volume":0.8,"fullscreen":false}, headers: @headers2, as: :json
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["event_type"], 2

		post '/en/courses/3/lectures/3/log_video_event', params: {"event":"seek","from_time":161.776062,"in_quiz":false,"speed":1,"volume":0.8,"fullscreen":false}, headers: @headers2, as: :json
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["event_type"], 3

		post '/en/courses/3/lectures/3/log_video_event', params: {"event":"fullscreen","from_time":161.776062,"in_quiz":false,"speed":1,"volume":0.8,"fullscreen":false}, headers: @headers2, as: :json
		assert_equal VideoEvent.where(lecture_id:3, group_id:3, course_id:3).last["event_type"], 4

	end

	test "get_lecture_data_angular requirement" do
		# lecture 3 is required and quiz 1 is required and its appearance time <= today
		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		assert_equal decode_json_response_body["lecture"]["requirements"], {"lecture"=>[], "quiz"=>[1]}

		Quiz.find(1).update_attribute(:appearance_time,Time.now + 2.days)
		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		assert_equal decode_json_response_body["lecture"]["requirements"], {"lecture"=>[], "quiz"=>[]}

	end

	test "get_lecture_data_angular next_item should be next lecture or quiz in group" do

		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		assert_equal decode_json_response_body["next_item"], {"id"=>4, "class_name"=>"lecture", "group_id"=>3}
		# if next item is lecture and inclass, its appearance time must be < today
		Lecture.find(4).update_attribute(:inclass,true)
		Lecture.find(4).update_attribute(:appearance_time,Time.now + 2.days)
		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		assert decode_json_response_body["next_item"].empty?

	end

	test "get_lecture_data_angular alert message should return due date" do

		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		lecture =lectures(:lecture3)
		due_date = I18n.localize(lecture.due_date, :format => '%d %b')
		days_to_today = (Time.zone.now.to_date - lecture.due_date.to_date).to_i
		assert_equal decode_json_response_body["alert_messages"], {"due"=>[due_date, days_to_today, "days"]}

	end

	test "get_lecture_data_angular should change updated_at of lecture_view or create new one if no lecture_views are present" do

		old_lecture_view = LectureView.where(lecture_id: 3).first

		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		# same lecture_view but changed updated_at
		## /10.floor to remove last digit because it fails because of seconds' differences, and we dont need to assert with that kind of precision
		assert_equal LectureView.where(lecture_id: 3).first.updated_at.to_i/10.floor, Time.zone.now.to_i/10.floor
		assert_equal LectureView.where(lecture_id: 3).first, old_lecture_view

		LectureView.where(lecture_id: 3).destroy_all

		get '/en/courses/3/lectures/3/get_lecture_data_angular', headers: @headers2
		# new lecture_view
		assert_equal LectureView.where(lecture_id: 3).first.updated_at.to_i/10.floor, Time.zone.now.to_i/10.floor
		assert_not LectureView.where(lecture_id: 3).first == old_lecture_view

	end

	test "should create new note if no id was sent" do

		notes = VideoNote.where(lecture_id:3, user_id:6).size

		post '/en/courses/3/lectures/3/save_note', params:{"data":"<p class=\"medium-editor-p\">note1</p>","time":10} , headers: @headers2, as: :json

		assert_equal decode_json_response_body["notice"], "Note was successfully saved"
		assert_equal  VideoNote.where(lecture_id:3, user_id:6).size, notes+1
	end

	test "should update note if id was sent" do

		VideoNote.create(lecture_id:3, user_id:6, data: "note data", id: 6)
		notes = VideoNote.where(lecture_id:3, user_id:6).size
		post '/en/courses/3/lectures/3/save_note', params:{"data":"<p class=\"medium-editor-p\">note1</p>","time":10, note_id: 6} , headers: @headers2, as: :json

		assert_equal decode_json_response_body["notice"], "Note was successfully saved"
		assert_equal decode_json_response_body["note"]["data"], "<p class=\"medium-editor-p\">note1</p>"
		assert_equal  VideoNote.where(lecture_id:3, user_id:6).size, notes
	end

	test "check_if_invited_distance_peer should respond with enrolled students if no invitations" do
		get "/en/courses/3/lectures/3/check_if_invited_distance_peer", headers: @headers2
		assert_equal decode_json_response_body["students"], [
			{"id"=>nil, "name"=>"Ahmed", "email"=>"ahmed@gmail.com", "last_name"=>"aly", "full_name"=>"Ahmed aly", "status"=>nil, "lower"=>"ahmed"},
			{"id"=>nil, "name"=>"Hossam", "email"=>"Hossam@gmail.com", "last_name"=>"aly", "full_name"=>"Hossam aly", "status"=>nil, "lower"=>"hossam"},
			{"id"=>nil, "name"=>"Karim", "email"=>"Karim@gmail.com", "last_name"=>"aly", "full_name"=>"Karim aly", "status"=>nil,"lower"=>"karim"},
			{"id"=>nil, "name"=>"Mohamed", "email"=>"Mohamed@gmail.com", "last_name"=>"aly", "full_name"=>"Mohamed aly", "status"=>nil, "lower"=>"mohamed"}]

		assert_equal decode_json_response_body["invite_status"], "no_invitation"
	end

	test "check_if_invited_distance_peer should respond with invited users" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:1,course_id:3,group_id:3,lecture_id:3,user_id:6)
		@student.user_distance_peers.create(online_quiz_id:4,distance_peer_id:1,status:0,online:false)
		UserDistancePeer.create(user_id:3,online_quiz_id:4,distance_peer_id:1,status:0,online:false)
		get "/en/courses/3/lectures/3/check_if_invited_distance_peer", headers: @headers2

		assert_equal decode_json_response_body["invite"],"a.okasha"
		assert_equal decode_json_response_body["invite_status"],"invited"
		assert_equal decode_json_response_body["distance_peer_id"],1
	end

	test "check_if_in_distance_peer_session should return user_distance_peer of user if same status" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:1,course_id:3,group_id:3,lecture_id:3,user_id:6)
		@student.user_distance_peers.create(id:1,online_quiz_id:4,distance_peer_id:1,status:1,online:false)
		UserDistancePeer.create(id:2,user_id:3,online_quiz_id:4,distance_peer_id:1,status:1,online:false)

		get "/en/courses/3/lectures/3/check_if_in_distance_peer_session", headers: @headers2

		assert_equal decode_json_response_body["distance_peer"]["id"], 1
		assert_equal decode_json_response_body["distance_peer"]["status"], 1


	end

	test "check_if_in_distance_peer_session should return other user's distance peer if different statuses and updated after" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:1,course_id:3,group_id:3,lecture_id:3,user_id:6)
		@student.user_distance_peers.create(id:1,online_quiz_id:4,distance_peer_id:1,status:1,online:false,updated_at:'2017-03-02')
		UserDistancePeer.create(id:2,user_id:3,online_quiz_id:4,distance_peer_id:1,status:2,online:false,updated_at:'2017-03-01')

		get "/en/courses/3/lectures/3/check_if_in_distance_peer_session", headers: @headers2

		assert_equal decode_json_response_body["distance_peer"]["id"], 2
		assert_equal decode_json_response_body["distance_peer"]["status"], 2


	end

	test "invite_student_distance_peer if not already invited" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)

		get "/en/courses/3/lectures/3/invite_student_distance_peer", params:{email:"okasha@gmail.com"}, headers: @headers2

		assert_equal UserDistancePeer.all.map{|u|u.status},[0,0]
	end

	test "invite_student_distance_peer if already invited should change status to 1" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:0,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:0,online:false)

		get "/en/courses/3/lectures/3/invite_student_distance_peer", params:{email:"okasha@gmail.com"}, headers: @headers2

		assert_equal UserDistancePeer.all.map{|u|u.status},[1,1]
	end

	test "check_invited_student_accepted_distance_peer " do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:1,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:1,online:false)

		get "/en/courses/3/lectures/3/check_invited_student_accepted_distance_peer", params:{distance_peer_id:5, email:"okasha@gmail.com"}, headers: @headers2

		assert_equal decode_json_response_body["status"], 1

		## denied (other user cancelled)
		UserDistancePeer.find(11).destroy
		get "/en/courses/3/lectures/3/check_invited_student_accepted_distance_peer", params:{distance_peer_id:5, email:"okasha@gmail.com"}, headers: @headers2
		assert_equal decode_json_response_body["status"],"denied"
	end

	test "accept_invation_distance_peer should update status to 1" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:0,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:0,online:false)

		get "/en/courses/3/lectures/3/accept_invation_distance_peer", params:{distance_peer_id:5, email:"okasha@gmail.com"}, headers: @headers2

		assert_equal decode_json_response_body["status"], 0
		assert_equal UserDistancePeer.all.map{|u|u.status},[1,1]

	end

	test "cancel_session_distance_peer should delete distance_peer" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:0,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:0,online:false)

		get "/en/courses/3/lectures/3/cancel_session_distance_peer", params:{distance_peer_id:5}, headers: @headers2

		assert_not DistancePeer.exists?(id:5)

		## distance peer doesnt exists

		get "/en/courses/3/lectures/3/cancel_session_distance_peer", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["distance_peer"],"deleted"
	end

	test "change_status_distance_peer" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:0,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:0,online:false)

		get "/en/courses/3/lectures/3/change_status_distance_peer", params:{distance_peer_id:5, online_quiz_id:5, status:3}, headers: @headers2

		assert_equal UserDistancePeer.find(10).status, 3
		assert_equal UserDistancePeer.find(10).online_quiz_id, 5

		## no distance_peer
		UserDistancePeer.find(10).destroy
		get "/en/courses/3/lectures/3/change_status_distance_peer", params:{distance_peer_id:5, online_quiz_id:5, status:3}, headers: @headers2
		assert_equal decode_json_response_body["distance_peer"], "no_peer_session"

	end

	test "check_if_distance_peer_status_is_sync" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:1,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:1,online:false)

		## same status for both users
		get "/en/courses/3/lectures/3/check_if_distance_peer_status_is_sync", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["status"],"start"

		UserDistancePeer.find(11).update_attribute('status',2)
		get "/en/courses/3/lectures/3/check_if_distance_peer_status_is_sync", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["status"],"wait"

		## no session
		UserDistancePeer.find(11).destroy
		get "/en/courses/3/lectures/3/check_if_distance_peer_status_is_sync", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["distance_peer"],"no_peer_session"

	end

	test "check_if_distance_peer_is_alive should end session if second user state is 6" do
		Enrollment.create(user_id:3, course_id:3)
		Enrollment.create(user_id:4, course_id:3)
		Lecture.find(3).update_attribute('distance_peer',true)
		DistancePeer.create(id:5,course_id:3,group_id:3,lecture_id:3,user_id:3)
		@student.user_distance_peers.create(id:10,online_quiz_id:4,distance_peer_id:5,status:1,online:false)
		UserDistancePeer.create(id:11,user_id:3,online_quiz_id:4,distance_peer_id:5,status:6,online:false)

		## one user ended session
		get "/en/courses/3/lectures/3/check_if_distance_peer_is_alive", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["status"],"dead"
		assert_equal UserDistancePeer.find(10).status, 6

		## session is alive
		UserDistancePeer.find(11).update_attribute('status',1)
		UserDistancePeer.find(10).update_attribute('status',1)
		get "/en/courses/3/lectures/3/check_if_distance_peer_is_alive", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["status"],"alive"

		## no session
		UserDistancePeer.find(11).destroy
		get "/en/courses/3/lectures/3/check_if_distance_peer_is_alive", params:{distance_peer_id:5}, headers: @headers2
		assert_equal decode_json_response_body["distance_peer"],"no_peer_session"

	end





	test "change_status_angular should change status assignment_item_status, or create new one with specified status" do
		# will create one if empty
		assert Lecture.find(3).assignment_item_statuses.empty?
		post "/en/courses/3/lectures/3/change_status_angular", params:{user_id:6, status: 2}, headers: @headers, as: :json
		assert_equal Lecture.find(3).assignment_item_statuses.first["status"], 2
		# will change existing if present
		post "/en/courses/3/lectures/3/change_status_angular", params:{user_id:6, status: 1}, headers: @headers, as: :json
		assert_equal Lecture.find(3).assignment_item_statuses.first["status"], 1
		assert_equal Lecture.find(3).assignment_item_statuses.size, 1


    end

	test "confused should add confused to lecture" do

		assert_changes 'Lecture.find(3).confuseds.where(time: 65).empty?', from: true, to: false do
			post '/en/courses/3/lectures/3/confused', params: {time: 65}, headers: @headers2, as: :json
		end
	end

	test "adding another confused in 15 seconds interval should update first to very " do
		# confused at 30 already exists with very set to false
		assert_changes 'Lecture.find(3).confuseds.where(time: 30).first.very', from: false, to: true do
			post '/en/courses/3/lectures/3/confused', params: {time: 36}, headers: @headers2, as: :json

		end
		assert_equal decode_json_response_body["msg"], "Saved"
		# confused at 30 already exists with very set to TRUE already
		post '/en/courses/3/lectures/3/confused', params: {time: 36}, headers: @headers2, as: :json
		assert_equal decode_json_response_body["msg"], "ask"

	end

	test "confused_show_inclass should show/hide confuseds" do
		assert_changes 'Lecture.find(3).confuseds.where(time: 30).first.hide', from: false, to: true do
			post '/en/courses/3/lectures/3/confused_show_inclass', params: {time: 30, hide: true, very: false}, headers: @headers, as: :json
		end

		assert_changes 'Lecture.find(3).confuseds.where(time: 30).first.hide', from: true, to: false do
			post '/en/courses/3/lectures/3/confused_show_inclass', params: {time: 30, hide: false, very: false}, headers: @headers, as: :json
		end

	end

	test "delete_note" do
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 6)
		assert_difference 'Lecture.find(3).video_notes.size', -1 do
			delete '/en/courses/3/lectures/3/delete_note', params: {note_id:6}, headers: @headers2
		end
		assert_equal VideoNote.where(id:6).size, 0
	end

	test "export_notes after adding 1 note in lecture" do
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 6)
		get '/en/courses/3/lectures/3/export_notes', params: {}, headers: @headers2
		resp =  JSON.parse(JSON.parse(response.body)['notes'][0])
		assert_response :success
		assert_equal resp.count , 1
	end
	test "export_notes after adding 2 note in lecture" do
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 6)
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 7)
		get '/en/courses/3/lectures/3/export_notes', params: {}, headers: @headers2
		assert_response :success
		resp =  JSON.parse(JSON.parse(response.body)['notes'][0])
		assert_equal resp.count , 2

	end
	test "export_notes after adding 2 note in lecture from 1 student and 1 note from different student" do
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 6)
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 7)
		VideoNote.create(lecture_id:3, user_id:8, data: "new note", id: 8)
		get '/en/courses/3/lectures/3/export_notes', params: {}, headers: @headers2
		resp =  JSON.parse(JSON.parse(response.body)['notes'][0])
		assert_response :success
		assert_equal resp.count , 2
	end
	test "export_notes after adding 2 note in lecture and then deleting 1 note  " do
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 6)
		VideoNote.create(lecture_id:3, user_id:6, data: "new note", id: 7)
		delete '/en/courses/3/lectures/3/delete_note', params: {note_id:6}, headers: @headers2
		get '/en/courses/3/lectures/3/export_notes', params: {}, headers: @headers2
		resp =  JSON.parse(JSON.parse(response.body)['notes'][0])
		assert_response :success
		assert_equal resp.count , 1
	end

end

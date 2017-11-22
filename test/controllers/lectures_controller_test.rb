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
		
		assert_equal @group3.lectures.count, 1

		get '/en/courses/3/lectures/new_lecture_angular', params: {distance_peer: false, group: 3, inclass: false}, headers: @headers
		
		@group3.reload
		
		assert_equal @group3.lectures.count, 2
		
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
		assert_equal lecture.appearance_time, '2017-10-6'
		assert_not lecture.due_date_module
		assert_equal lecture.due_date, '2017-10-7'
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
		
	
		## parent module has required ==false and graded ==false
		put '/en/courses/3/lectures/3', params: {:lecture => {required_module: true, graded_module: true, appearance_time_module: true, due_date_module: true}}, headers: @headers, as: :json
		
		lecture.reload
		assert_not lecture.required
		assert_not lecture.graded
		assert_equal lecture.appearance_time, '2017-9-9'
		assert_equal lecture.due_date, '2017-10-9'
		
	end

	test "should copy lecture to same group" do

		group = Group.find(3)

		assert_equal group.lectures.size, 1

		post '/en/courses/3/lectures/lecture_copy', params: {lecture_id: 3, module_id: 3}, headers: @headers, as: :json

		assert_equal group.lectures.size, 2
		
		
		lecture_from = Lecture.find(3)
		new_lecture = Lecture.last

		assert_equal lecture_from.name, new_lecture.name
		assert_equal lecture_from.url, new_lecture.url
		## due_date and appearance_time is copied from parent group
		assert_equal group.due_date, new_lecture.due_date
		assert_equal group.appearance_time, new_lecture.appearance_time

		
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
		assert_equal lecture.online_quizzes.last_created_record.question, "New Survey"
		
		
		get '/en/courses/3/lectures/3/new_quiz_angular', params:{end_time:28, inclass:false,ques_type:"OCQ",quiz_type:"html_survey",start_time:28,time:28}, headers: @headers
		lecture.reload
		assert_equal lecture.online_quizzes.last_created_record.question, "New Survey"
		
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
	
	test "should new_marker " do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/new_marker'
		get url , params: {time: 11.2},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response :success
		assert_equal resp['marker']['time'] , 11.2	
	end
	test "should new_marker for empty params" do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/new_marker'
		get url , params: {},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response 400		
		assert_equal resp['errors']['time'][0] , "can't be blank"	
	end
	test "should new_marker for invalif time" do
		url = '/en/courses/'+@course1.id.to_s+'/lectures/'+@lecture1.id.to_s+'/new_marker'
		get url , params: { time: "dsadasd"},headers: @user1.create_new_auth_token 
		resp =  JSON.parse response.body
		assert_response 400		
		assert_equal resp['errors']['time'][0] , "is not a number"
	end

end

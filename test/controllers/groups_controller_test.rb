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
		
		## teacher in course 3
		@user3 = users(:user3)
		@user3.roles << Role.find(1)
		@course3 = courses(:course3)
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

		@group3_course1 = groups(:group3_course1)
		@assignment_statuses_course1 =  assignment_statuses(:assignment_statuses_course1)

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
		
		# p response.body
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

		## [time, no. of occurrences within 15 seconds range]
		assert_equal decode_json_response_body["confused"], [[1511308800, 2], [1511308830, 1]]
		assert_equal decode_json_response_body["really_confused"], [[1511308845, 1]]
		
	end

	test "statistics should return array of backs " do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		assert_equal decode_json_response_body["back"], [[1511308845, 1]]

		## from_time - to_time must be >= 15
		VideoEvent.find(1).update(to_time: 20)
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		assert_equal decode_json_response_body["back"], []
	end

	test "statistics should return array of pauses " do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		assert_equal decode_json_response_body["pauses"], [[1511308860, 1]]

	end

	test "statistics should return width, time_list, min, max and lecture_names " do

		##@user3 is teacher in course3
		get '/en/courses/3/groups/3/get_student_statistics_angular', headers: @user3.create_new_auth_token

		## total time of lectures in group
		assert_equal decode_json_response_body["width"], 390

		assert_equal decode_json_response_body["time_list"], {"240.0"=>"http://www.youtube.com/watch?v=xGcG4cp2yzY", "390.0"=>"http://www.youtube.com/watch?v=xGcGdfrty"}
		
		assert_equal decode_json_response_body["lecture_names"], [[240.0, "lecture3"], [150.0, "lecture4"]]
		assert_equal decode_json_response_body["min"], 1511308800
		assert_equal decode_json_response_body["max"], 1511309190

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
		assert_equal resp['total_questions'] , 3  
		assert_equal resp['total_quiz_questions'] , 3 
		assert_equal resp['total_survey_questions'] , 0
		assert_equal resp['total_lectures'] , 2 
		assert_equal resp['total_quizzes'] , 1 
		assert_equal resp['total_surveys'] , 0
		assert_equal resp['total_links'] , 2 
	end
	
end
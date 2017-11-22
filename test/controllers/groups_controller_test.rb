require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)
		@student1 = users(:student1)

		@course1 = courses(:course1)
		@course2 = courses(:course2)

		@group1 = groups(:group1)
		@group2 = groups(:group2)

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
		user = users(:user3)

		user.roles << Role.find(1)
	
		course = courses(:course3)

		##here user is not a teacher in course
		put '/en/courses/3/groups/3/', params: {group: {graded: true}}, headers: user.create_new_auth_token

		assert_response :forbidden
		
		## here we assign the user a teacher to that course
		course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
		
		put '/en/courses/3/groups/3/', params: {group: {graded: true}}, headers: user.create_new_auth_token

		assert_response :success
		
	end
	
	test "user should be able delete a group in a course he is a teacher in" do
		user = users(:user3)

		user.roles << Role.find(1)
	
		course = courses(:course3)

		##here user is not a teacher in course
		delete '/en/courses/3/groups/3/', headers: user.create_new_auth_token

		assert_response :forbidden
		
		## here we assign the user a teacher to that course
		course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
		
		delete '/en/courses/3/groups/3/', headers: user.create_new_auth_token

		assert_response :success
		
	end

	test "sort action should sort groups" do
		user = users(:user3)

		user.roles << Role.find(1)
	
		course = courses(:course3)

		course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

		assert_equal course.groups.find(3).position, 3
		assert_equal course.groups.find(4).position, 1
		assert_equal course.groups.find(5).position, 2
		
		post '/en/courses/3/groups/sort', params: {group:[{id: 3, course_id: 3},{id: 4, course_id: 3},{id: 5, course_id: 3}]},headers: user.create_new_auth_token
		
		assert_equal course.groups.find(3).position, 1
		assert_equal course.groups.find(4).position, 2
		assert_equal course.groups.find(5).position, 3
		
	end

	test "should create new link" do
		user = users(:user3)

		user.roles << Role.find(1)
	
		course = courses(:course3)

		course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

		group = groups(:group3)

		assert_equal group.custom_links.count, 2

		post '/en/courses/3/groups/3/new_link_angular', headers: user.create_new_auth_token

		assert_equal group.custom_links.count, 3
		
	end

	test "should copy/paste group" do
		user = users(:user3)

		user.roles << Role.find(1)
	
		post '/en/courses/3/groups/module_copy', params: {module_id: 3}, headers: user.create_new_auth_token

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


end

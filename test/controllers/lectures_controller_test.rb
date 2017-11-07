require 'test_helper'

class LecturesControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
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
		assert_equal lecture.appearance_time, '2017-9-9'
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
end

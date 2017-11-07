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
		user = users(:user3)

		user.roles << Role.find(1)
	
		course = courses(:course3)

		group = course.groups.find(3)
		
		assert_equal group.custom_links.find(1).position,1
		assert_equal group.custom_links.find(2).position,2
		assert_equal group.quizzes.find(1).position,3
		assert_equal group.lectures.find(353640512).position,4
		

		course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

		post '/en/courses/3/lectures/sort', params: {items:
			[
				{id: 1 , "class_name": "quiz"},{id: 1, class_name: "customlink"},
				{id: 2, class_name: "customlink"}, {id: 353640512, class_name: "lecture"}
			], 
			group: 3}, headers: user.create_new_auth_token
		
		group.reload

		assert_equal group.custom_links.find(1).position,2
		assert_equal group.custom_links.find(2).position,3
		assert_equal group.quizzes.find(1).position,1
		assert_equal group.lectures.find(353640512).position,4
		
	end

end

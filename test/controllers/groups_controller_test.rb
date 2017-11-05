require 'test_helper'

class GroupsControllerTest < ActionDispatch::IntegrationTest
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
end

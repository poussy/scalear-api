require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
	def setup
		@user1 = users(:user1)
		@user2 = users(:user2)

		@course1 = courses(:course1)
		@course2 = courses(:course2)
	end

	test "Validate abilities for user1" do
		ability1 = Ability.new(@user1)
		assert ability1.can?(:create, Course)
		assert ability1.can?(:destroy, @course1)
		assert ability1.cannot?(:destroy, @course2)
		assert ability1.can?(:teachers, @course1)
		assert ability1.cannot?(:getCourse, @course1)
	end

	test "Validate abilities for user2" do
		ability2 = Ability.new(@user2)
		assert ability2.can?(:create, Course)

		assert ability2.cannot?(:destroy, @course1)
		assert ability2.can?(:destroy, @course2)

		assert ability2.can?(:teachers, @course2)
		assert ability2.cannot?(:getCourse, @course2)

		@course1.add_professor(@user2 , false)
		assert ability2.can?(:destroy, @course1)
		assert ability2.can?(:destroy, @course2)
	end
end

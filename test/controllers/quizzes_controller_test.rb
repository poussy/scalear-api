require 'test_helper'

class QuizzesControllerTest < ActionDispatch::IntegrationTest
  def setup
    ## create user for authorization, and set this user to be a teacher in course3, below tests wil use items in course3
    @user = users(:user3)

		@user.roles << Role.find(1)
	
		@course = courses(:course3)

		@course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
    
  end

  test "should create quiz" do

    assert_equal Quiz.count, 1

		post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'quiz'},headers: @user.create_new_auth_token

    assert_equal Quiz.count, 2
    
		
	end


end

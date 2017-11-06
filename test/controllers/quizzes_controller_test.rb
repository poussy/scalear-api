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

  test "should be able to edit quiz" do

    quiz = quizzes(:quiz1)

    assert quiz.required
    assert_equal quiz.appearance_time, '2017-9-9'
    assert quiz.due_date_module
    assert_equal quiz.due_date, '2017-10-9'
    assert_equal quiz.position, 3
    assert quiz.graded
    assert quiz.visible
    assert_equal quiz.retries, 2

		put '/en/courses/3/quizzes/1', params:{:quiz => {required: false, appearance_time: '2017-10-10',appearance_time_module: false, due_date_module: false,
        due_date: '2017-10-10', position: 1, graded: false, visible: false, retries: 5}}, headers: @user.create_new_auth_token

    quiz.reload
    assert_not quiz.required
    assert_equal quiz.appearance_time, '2017-10-10'
    assert_not quiz.due_date_module
    assert_equal quiz.due_date, '2017-10-10'
    assert_equal quiz.position, 1
    assert_not quiz.graded
    assert_not quiz.visible
    assert_equal quiz.retries, 5
		
	end

  test "should update graded and required according to parent module's" do

    quiz = quizzes(:quiz1)

    assert quiz.required
    assert quiz.graded
    ## necessary to send as json, so true and false wouldn't convert to strings
    headers = @user.create_new_auth_token
    headers['content-type']="application/json"
   
   ## parent module has required ==false and graded ==false
		put '/en/courses/3/quizzes/1', params: {:quiz => {required_module: true, graded_module: true}}, headers: headers, as: :json
    
    quiz.reload
    assert_not quiz.required
    assert_not quiz.graded
		
	end




end

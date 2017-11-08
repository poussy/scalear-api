require 'test_helper'

class QuizzesControllerTest < ActionDispatch::IntegrationTest
  def setup
    ## create user for authorization, and set this user to be a teacher in course3, below tests wil use items in course3
    @user = users(:user3)

		@user.roles << Role.find(1)
	
		@course = courses(:course3)
    @course4 = courses(:course4)

		@course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
		@course4.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

    ## necessary to send as json, so true and false wouldn't convert to strings
    @headers = @user.create_new_auth_token
    @headers['content-type']="application/json"
    
  end

  test "should be able to create quiz" do

    assert_equal Quiz.count, 2

		post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'quiz'},headers: @user.create_new_auth_token

    assert_equal Quiz.count, 3
		
	end

  test "should be able to create survey" do

    assert_equal Quiz.count, 2

		post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'survey'},headers: @user.create_new_auth_token

    assert_equal Quiz.count, 3
		
	end


  test "should throw error if quiz id is not present with correct course id" do

    ## quiz with id 2 exists but not in course with id 3
    put '/en/courses/3/quizzes/2', params:{:quiz => {required: false, appearance_time: '2017-10-10',appearance_time_module: false, due_date_module: false,
        due_date: '2017-10-10', position: 1, graded: false, visible: false, retries: 5}}, headers: @user.create_new_auth_token

    assert (JSON.parse response.body)['errors'].include? "No such quiz"
		
	end



  test "should be able to edit quiz" do

    quiz = quizzes(:quiz1)

    assert quiz.required
    assert_equal quiz.appearance_time, '2017-9-10'
    assert quiz.due_date_module
    assert_equal quiz.due_date, '2017-9-11'
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

  test "should update graded,required, due_date and appearnce_time according to parent module's" do

    quiz = quizzes(:quiz1)

    assert quiz.required
    assert quiz.graded
    assert_equal quiz.appearance_time, '2017-9-10'
		assert_equal quiz.due_date, '2017-9-11'
   
   ## parent module has required ==false and graded ==false
		put '/en/courses/3/quizzes/1', params: {:quiz => {required_module: true, graded_module: true, appearance_time_module: true, due_date_module: true}}, headers: @headers, as: :json
    
    quiz.reload
    assert_not quiz.required
    assert_not quiz.graded
		assert_equal quiz.appearance_time, '2017-9-9'
		assert_equal quiz.due_date, '2017-10-9'
	end

  test "should be able to delete quiz" do

    assert Quiz.where(id: 1).present?
    
    ## parent module has required ==false and graded ==false
		delete '/en/courses/3/quizzes/1', headers: @headers
    
    assert_not Quiz.where(id: 1).present?
    
	end

  test "should not be able to delete other teachers' quizzes" do

		@course.teacher_enrollments.where({:user_id => 3, :role_id => 1, :email_discussion => false}).destroy_all
    

    assert Quiz.where(id: 1).present?
    
    ## parent module has required ==false and graded ==false
		delete '/en/courses/3/quizzes/1', headers: @headers

    assert (JSON.parse response.body)['errors'].include? "You are not authorized to see requested page"
    
    assert Quiz.where(id: 1).present?
    
	end




end

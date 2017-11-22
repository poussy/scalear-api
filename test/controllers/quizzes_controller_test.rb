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

    assert_equal Quiz.count, 4

		post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'quiz'},headers: @user.create_new_auth_token

    assert_equal Quiz.count, 5
		
	end

  test "should be able to create survey" do

    assert_equal Quiz.count, 4

		post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'survey'},headers: @user.create_new_auth_token

    assert_equal Quiz.count, 5
		
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
    assert_equal quiz.appearance_time, Time.parse('2017-10-10')
    assert_not quiz.due_date_module
    assert_equal quiz.due_date, Time.parse('2017-10-10')
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

  test "should copy quiz" do

    assert_equal Quiz.count, 4
	
		post '/en/courses/3/quizzes/quiz_copy', params: {module_id: 3, quiz_id: 1}, headers: @headers, as: :json

    assert_equal Quiz.count, 5

    	quiz_from = Quiz.find(1)
    new_quiz = Quiz.last

    assert_equal quiz_from.name, new_quiz.name
    assert_equal quiz_from.retries, new_quiz.retries
    assert_equal quiz_from.instructions, new_quiz.instructions
    assert_equal quiz_from.required, new_quiz.required
    assert_equal quiz_from.graded, new_quiz.graded

    assert_not_equal quiz_from.id, new_quiz.id

	end

  test "should add question if sent with no id and delete other questions from database" do
    ## array of old questions ids
    old_questions = Question.all.each.map {|q| q.id}
    ## question sent in params doesnt have an id
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{ content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "MCQ", quiz_id: 1}]}, headers: @headers, as: :json
    
    assert_equal Question.count, 1
    assert_equal Question.first.content, '<p class="medium-editor-p">new mcq</p>'
    assert_equal Question.first.question_type, 'MCQ'
    ## assert that it is a newly created question with new id
    assert_not old_questions.include? Question.first.id


	end

  test "should add question if sent with no id and add its answers" do
   
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{ answers: [{id: 1, content:"a1", correct: true, explanation: "answer explanation" }], content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "MCQ", quiz_id: 1}]}, headers: @headers, as: :json
    
    assert_equal Question.first.answers.count, 1
    assert_equal Question.first.answers.first.content, 'a1'
    
    


	end

  test "should edit question if sent with id and delete other questions from database" do
    
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{id: 1, content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "MCQ", quiz_id: 1}]}, headers: @headers, as: :json
    
    assert_equal Question.count, 1
    assert_equal Question.first.content, '<p class="medium-editor-p">new mcq</p>'
    ## same old question
    assert Question.first.id, 1
    assert_equal Question.first.content, '<p class="medium-editor-p">new mcq</p>'
    assert_equal Question.first.question_type, 'MCQ'

	end

  test "should update old answers if sent with id" do
    
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{answers: [{id: 1, content:"a1", correct: true, explanation: "answer explanation" }],id: 1, content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "MCQ", quiz_id: 1}]}, headers: @headers, as: :json
    
    answer = Question.first.answers.find(1)
    assert answer.correct
    assert_equal answer.content, "a1"
    assert_equal answer.explanation, "answer explanation"
    assert_equal answer.explanation, "answer explanation"
   
	end

  test "should create new answers if sent with no id" do
    
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{answers: [{content:"a1", correct: true, explanation: "answer explanation" }],id: 1, content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "MCQ", quiz_id: 1}]}, headers: @headers, as: :json
    
    answer = Question.find(1).answers.first
    assert answer.correct
    assert_equal answer.content, "a1"
    assert_equal answer.explanation, "answer explanation"
    assert_equal answer.explanation, "answer explanation"
   
	end

  test "should delete old answers and put new ones with no content" do ## if the question_type == 'Free Text Question && match_type == 'Free Text'

		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{answers: [{id: 1,content:"a3", correct: true, explanation: "answer explanation" }],id: 1, content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "Free Text Question", quiz_id: 1}]}, headers: @headers, as: :json
    
    ## not the same old answer, old one is deleted and this is a new one
    assert_not_equal Question.first.answers.first.id, 1

    answer = Question.first.answers.first
    assert answer.correct
    assert_equal answer.content, ""
    assert_equal answer.explanation, "answer explanation"
    
   
	end

  test "should be able to create quiz header" do
    
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{id: 1, content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "header", quiz_id: 1}]}, headers: @headers, as: :json
    
    assert_equal Question.find(1).question_type, "header"
   
	end





end

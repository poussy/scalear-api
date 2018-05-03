require 'test_helper'

class QuizzesControllerTest < ActionDispatch::IntegrationTest
    def setup
        ## create user for authorization, and set this user to be a teacher in course3, below tests wil use items in course3
        @user = users(:user3)
        @student = users(:student_in_course3)
    	@headers2 = @student.create_new_auth_token
    	@headers2['content-type']="application/json"
    	
    	@course = courses(:course3)
        @course4 = courses(:course4)

    	@course.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
    	@course4.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)

        ## necessary to send as json, so true and false wouldn't convert to strings
        @headers = @user.create_new_auth_token
        @headers['content-type']="application/json"
    end

    test "should be able to create quiz" do
        assert_difference 'Quiz.count' do
	       post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'quiz'},headers: @user.create_new_auth_token
		end
	end

    test "should be able to create survey" do
        assert_difference 'Quiz.count' do 
            post '/en/courses/3/quizzes/new_or_edit/', params:{:group => 3, :type => 'survey'},headers: @user.create_new_auth_token
		end
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

		put '/en/courses/3/quizzes/1', params:{:quiz => {required: false, appearance_time: '2017-09-15',appearance_time_module: false, due_date_module: false,
        due_date: '2017-10-8', position: 1, graded: false, visible: false, retries: 5}}, headers: @user.create_new_auth_token

    quiz.reload
    assert_not quiz.required
    assert_equal quiz.appearance_time, Time.zone.parse('2017-09-15')
    assert_not quiz.due_date_module
    assert_equal quiz.due_date, Time.zone.parse('2017-10-8')
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
        resp = JSON.parse response.body
        assert resp['errors'].include? "You are not authorized to see requested page"
        assert Quiz.where(id: 1).present?
	end

    test "should copy quiz" do
        assert_difference ['Quiz.count', 'Event.count'] do
            post '/en/courses/3/quizzes/quiz_copy', params: {module_id: 3, quiz_id: 1}, headers: @headers, as: :json
        end

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
    
		put '/en/courses/3/quizzes/1/update_questions_angular', params: {questions: [{answers: [{id: 4, content:"a1", correct: true, explanation: "answer explanation" }],id: 1, content: '<p class="medium-editor-p">new mcq</p>', match_type: "Free Text", question_type: "MCQ", quiz_id: 1}]}, headers: @headers, as: :json
    assert Question.first.answers.where(id: 5).empty?
    answer = Question.first.answers.find(4)
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

    test 'should be able get_questions_angular for teacher' do        
        url = '/en/courses/3/quizzes/1/get_questions_angular'
        get  url ,headers: @user.create_new_auth_token , as: :json
        resp =  JSON.parse response.body
        assert_equal resp['quiz']['retries'] , 2
        assert_equal resp['questions'].count , 6
    end

    test 'validate validate_quiz_angular method ' do
        url = '/en/courses/3/quizzes/1/validate_quiz_angular/'
        put  url , params: {quiz: { name:'toto' } } ,headers: @user.create_new_auth_token , as: :json
        assert_response :success
        resp =  JSON.parse response.body
        assert_equal resp['nothing'] , true
    end
    test 'validate validate_quiz_angular method and respone 422' do
        url = '/en/courses/3/quizzes/1/validate_quiz_angular/'
        put  url , params: {quiz: { due_date_module:false ,  due_date:DateTime.now + 3.months } } ,headers: @user.create_new_auth_token 
        assert_response 422
        resp =  JSON.parse response.body
        assert_equal resp['errors'].count , 1
        assert_equal resp['errors'][0] , "Due date must be before module due date"
    end
    test 'validate validate_quiz_angular method and respone 422 for retries is not position' do
        url = '/en/courses/3/quizzes/1/validate_quiz_angular/'
        put  url , params: {quiz: { due_date_module:false ,  due_date:DateTime.now + 3.months , retries:-9 }} ,headers: @user.create_new_auth_token 
        assert_response 422
        resp =  JSON.parse response.body
        assert_equal resp['errors'].count , 2
        assert_equal resp['errors'][0] , "Retries must be greater than or equal to 0"
        assert_equal resp['errors'][1] , "Due date must be before module due date"
    end
    test 'validate validate_quiz_angular method and respone 422 for title is empty' do
        url = '/en/courses/3/quizzes/1/validate_quiz_angular/'
        put  url , params: {quiz: { name:'' }} ,headers: @user.create_new_auth_token 
        assert_response 422
        resp =  JSON.parse response.body
        assert_equal resp['errors'].count , 1
        assert_equal resp['errors'][0] , "Name can't be blank"
    end

    test 'get_questions_angular for student' do        

        get '/en/courses/3/quizzes/1/get_questions_angular' ,headers: @headers2 , as: :json

        assert_equal decode_json_response_body["quiz"]["name"], quizzes(:quiz1)["name"]
        assert_equal decode_json_response_body["questions"].size, 6
        assert_equal decode_json_response_body["answers"][0], 
            [{"id"=>4,"question_id"=>1,"content"=>"<p class=\"medium-editor-p\">a1</p>"},
             {"id"=>5,"question_id"=>1,"content"=>"<p class=\"medium-editor-p\">a2</p>"}]

        assert_equal decode_json_response_body["answers"][1],  
            [{"id"=>1,"question_id"=>2,"content"=>"<p class=\\\"medium-editor-p\\\">a1</p>"},
              {"id"=>2,"question_id"=>2,"content"=>"<p class=\\\"medium-editor-p\\\">a2</p>"}]
        
        assert_equal decode_json_response_body["answers"][2], [{"id"=>6, "question_id"=>3, "content"=>"abcd"}]
        #because it is shuffled we cannot predict the exact answer
        assert decode_json_response_body["answers"][3] == [{"id"=>3,"question_id"=>4,"content"=>["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"],"explanation"=>[]}] || 
                decode_json_response_body["answers"][3] == [{"id"=>3,"question_id"=>4,"content"=>["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],"explanation"=>[]}]
       
    end

    test 'get_questions_angular shold return next_item if quiz was submitted' do    
      # submit answer
      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":5,
            "2":{"1":false, "2":true},
            "3":"abcd",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"]
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json


      get '/en/courses/3/quizzes/1/get_questions_angular' ,headers: @headers2 , as: :json

      assert_equal decode_json_response_body["next_item"], {"id"=>3, "class_name"=>"lecture", "group_id"=>3}
       
    end

    test "save_student_quiz_angular should return status" do
      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":5,
            "2":{"1":false, "2":true},
            "3":"abcd",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"]
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json

        assert_equal decode_json_response_body["status"]["status"], "Submitted"
        assert_equal decode_json_response_body["status"]["attempts"], 2
    end
    
    test "save_student_quiz_angular should return result and explanations" do
      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":5,
            "2":{"1":false, "2":true},
            "3":"abcd",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"],
            "5": "waterloo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
       
        # all question are correct, 1 is correct for mcq, ocq or drag, 3 is correct for free text with match
        assert_equal decode_json_response_body["correct"], {"1"=>1, "2"=>1, "3"=>3, "4"=>1, "5"=>3, "6"=>0}
        assert_equal decode_json_response_body["explanation"], 
        {
          "4"=>"<p class=\"medium-editor-p\">exp1</p>",
          "5"=>"<p class=\"medium-editor-p\">exp2</p>",
          "1"=>"<p class=\\\"medium-editor-p\\\">exp 1</p>",
          "2"=>"<p class=\\\"medium-editor-p\\\">exp 2</p>",
          "6"=>"<p class=\"medium-editor-p\">exp free text</p>",
          "3"=>
            ["<p class=\"medium-editor-p\">exp1</p>",
            "<p class=\"medium-editor-p\">exp2</p>"],
          "7"=>"<p class=\"medium-editor-p\">exp free text</p>",
          "8"=>"<p class=\"medium-editor-p\">exp free text</p>"
        }
    end

    test "save_student_quiz_angular should create quiz_status with right number of attempts" do
      # first attempt
      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4,
            "2":{"1":false, "2":true},
            "3":"aaa",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"]
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json

        assert_not QuizStatus.where(quiz_id:1, user_id:6).empty?
        assert_equal QuizStatus.where(quiz_id:1, user_id:6).first["attempts"], 2

        # second attempt
        post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":5,
            "2":{"1":false, "2":true},
            "3":"abcd",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"]
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json

        assert_equal QuizStatus.where(quiz_id:1, user_id:6).first["attempts"], 3
    end

    test "save_student_quiz_angular should create quiz_grades for mcq and ocq " do

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4,
            "2":{"1":false, "2":true},
            "3":"abcd",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"],
            "5": "waterloo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      

      assert_equal QuizGrade.where(quiz_id:1, user_id:6).size, 2
      assert_equal QuizGrade.where(quiz_id:1, question_id: 1).first.grade, 0
      assert_equal QuizGrade.where(quiz_id:1, question_id: 2).first.grade, 1
    end

    test "save_student_quiz_angular should create free_answers for drag and free_text " do

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4,
            "2":{"1":false, "2":true},
            "3":"abcd",
            "4": ["<p class=\"medium-editor-p\">ans1</p>","<p class=\"medium-editor-p\">ans2</p>"],
            "5": "waterloo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6).size, 4
      # grade 1 is incorrect in free text, grade 3 is correct
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 3).first.grade, 3
      # grade 1 is correct in drag, grade 0 is incorrect
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 4).first.grade, 1
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 5).first.grade, 3
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 6).first.grade, 0

    end
    
    test "save_student_quiz_angular wrong answers" do

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4, 
            "2":{"1":true, "2":true},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      # mcq has quiz grade for every choice
      assert_equal QuizGrade.where(quiz_id:1, user_id:6).size, 3
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6).size, 4
      
      assert_equal QuizGrade.where(quiz_id:1, question_id: 1).first.grade, 0
      assert_equal QuizGrade.where(quiz_id:1, question_id: 2).first.grade, 0
      # grade 1 is incorrect in free text, grade 3 is correct
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 3).first.grade, 1
      # grade 1 is correct in drag, grade 0 is incorrect
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 4).first.grade, 0
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 5).first.grade, 1
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6, question_id: 6).first.grade, 0

    end

    test "save_student_quiz_angular any empty answer should rollback other answers grades" do

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1": '', 
            "2":{"1":true, "2":true},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      
      assert_equal QuizGrade.where(quiz_id:1, user_id:6).size, 0
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6).size, 0

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1": 4, 
            "2":{"1":false, "2":false},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      
      assert_equal QuizGrade.where(quiz_id:1, user_id:6).size, 0
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6).size, 0

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1": 4, 
            "2":{"1":false, "2":false},
            "3": "", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      
      assert_equal QuizGrade.where(quiz_id:1, user_id:6).size, 0
      assert_equal FreeAnswer.where(quiz_id:1, user_id:6).size, 0
    end

    test "save_student_quiz_angular should update quiz_status" do

      assert QuizStatus.where(quiz_id:1, course_id: 3, user_id: 6).empty?
      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4, 
            "2":{"1":true, "2":true},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json
      
      assert_equal QuizStatus.where(quiz_id:1, course_id: 3, user_id: 6).first["status"], "Submitted"
        
    end

    test "change_status_angular should change status assignment_item_status, or create new one with specified status" do
      # will create one if empty
      assert Quiz.find(1).assignment_item_statuses.empty?
      post "/en/courses/3/quizzes/1/change_status_angular", params:{user_id:6, status: 2}, headers: @headers, as: :json
      assert_equal Quiz.find(1).assignment_item_statuses.first["status"], 2
      # will change existing if present
      post "/en/courses/3/quizzes/1/change_status_angular", params:{user_id:6, status: 1}, headers: @headers, as: :json
      assert_equal Quiz.find(1).assignment_item_statuses.first["status"], 1
      assert_equal Quiz.find(1).assignment_item_statuses.size, 1
      
    end
      
    test "save_student_quiz_angular student can save if not submitted" do

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4, 
            "2":{"1":true, "2":true},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"save"
        }, 
        headers: @headers2 , as: :json

      assert_equal QuizStatus.where(quiz_id:1, course_id: 3, user_id: 6).first["status"], "Saved"

    end

    test "save_student_quiz_angular student cannot save if already submitted" do

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4, 
            "2":{"1":true, "2":true},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"submit"
        }, 
        headers: @headers2 , as: :json

      post '/en/courses/3/quizzes/1/save_student_quiz_angular' , 
        params: {
          "student_quiz":{
            "1":4, 
            "2":{"1":true, "2":true},
            "3": "abcde", 
            "4": ["<p class=\"medium-editor-p\">ans2</p>","<p class=\"medium-editor-p\">ans1</p>"],
            "5": "waterlo",
            "6": "any asnwer here will give grade 0"
          },
          "commit":"save"
        }, 
        headers: @headers2 , as: :json

      assert_equal decode_json_response_body["errors"], ["Can't Save - Already Submitted Quiz"]

      assert_equal QuizStatus.where(quiz_id:1, course_id: 3, user_id: 6).first["status"], "Submitted"

    end

    test "show_question_inclass should toggle show of selected quiz to true or false" do
      
      assert_changes 'Question.find(1).show', from: false, to: true do
        post '/en/courses/3/quizzes/1/show_question_inclass', params: {question: 1, show:true}, headers: @headers, as: :json
      end

      assert_changes 'Question.find(1).show', from: true, to: false do
        post '/en/courses/3/quizzes/1/show_question_inclass', params: {question: 1, show:false}, headers: @headers, as: :json
      end
    end

    test "create_or_update_survey_responses should add response to free answer" do
      FreeAnswer.create(id: 1,user_id: 6, quiz_id:1, question_id: 5,answer: '<p class=\"medium-editor-p\">ans1</p>', hide: true, grade: 0, student_hide: false, response:"")
      post '/en/courses/3/quizzes/1/create_or_update_survey_responses', params: {groups: [1],response:"response to answer1"}, headers: @headers, as: :json
      assert_equal FreeAnswer.find(1).response, "response to answer1"
    end

    test "make_visible should make survey visible" do
      Quiz.find(1).update_attributes({quiz_type:'survey',visible:false})
      assert_changes 'Quiz.find(1).visible', from: false, to: true do
        post '/en/courses/3/quizzes/1/make_visible', params: {visible: true}, headers: @headers, as: :json
      end
      assert_equal decode_json_response_body, {"notice"=>["Survey is now visible"]}
    end
    
end

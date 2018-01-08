require 'test_helper'

class OnlineQuizzesControllerTest < ActionDispatch::IntegrationTest
  def setup

		## @user3 is teacher in @course3
		@user3 = users(:user3)
		@user3.roles << Role.find(1)
		@course3 = courses(:course3)
		@course3.teacher_enrollments.create(:user_id => 3, :role_id => 1, :email_discussion => false)
    @online_quiz1 = online_quizzes(:online_quiz1)

		## necessary to send as json, so true and false wouldn't convert to strings
    @headers = @user3.create_new_auth_token
    @headers['content-type']="application/json"

    @student = users(:student_in_course3)
		@headers2 = @student.create_new_auth_token
		@headers2['content-type']="application/json"
  end

  test "should update online_quiz with sent paramaters" do

    assert_equal @online_quiz1.display_text, true
    assert_equal @online_quiz1.start_time, 100
    assert_equal @online_quiz1.time, 20
    assert_equal @online_quiz1.end_time, 120
    assert_equal @online_quiz1.graded, false
    assert_equal @online_quiz1.inclass, false
    put '/en/online_quizzes/1', params: {online_quiz: {display_text:false, start_time:10, time:40, end_time:50, 
                                                        graded:true, inclass:true, question:"New Quiz"}}, headers: @headers, as: :json
    
    @online_quiz1.reload
    assert_equal @online_quiz1.display_text, false
    assert_equal @online_quiz1.start_time, 10
    assert_equal @online_quiz1.time, 40
    assert_equal @online_quiz1.end_time, 50
    assert_equal @online_quiz1.graded, true
    assert_equal @online_quiz1.inclass, true
  end

  test "should set hide attribute according to inclass" do
    assert_equal @online_quiz1.hide, true

    put '/en/online_quizzes/1', params: {online_quiz: {inclass:true, display_text:false, start_time:10, time:40, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
    @online_quiz1.reload
    assert_equal @online_quiz1.hide, false

    put '/en/online_quizzes/1', params: {online_quiz: {inclass:false, display_text:false, start_time:10, time:40, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
    @online_quiz1.reload
    assert_equal @online_quiz1.hide, true
    
  end

  test "should send alert if another quiz is within 5 seconds" do

     put '/en/online_quizzes/2', params: {online_quiz: {inclass:false, display_text:false, start_time:10, time:22, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
                                                  
    assert_equal decode_json_response_body['alert'], "There's another quiz within 5 seconds from this one - consider shifting it."
    
  end

  test "should send empty response if valid attributes are sent" do

     put '/en/online_quizzes/1/validate_name', params: {online_quiz: {inclass:false, display_text:false, start_time:10, end_time:50, 
                                                      graded:true, question:"New Quiz"}}, headers: @headers, as: :json
                                                  
    assert_response 200
    assert_equal response.headers["Content-length"], "0"

  end

  test "should return list of online_quizzes of lecture" do
    get '/en/online_quizzes/get_quiz_list_angular', params: {lecture_id: 3}, headers: @headers

    lecture = lectures(:lecture3)

    assert_equal decode_json_response_body['quizList'].count, lecture.online_quizzes.count

  end

  test "should add match_type='Free Text' attribute to quiz if question_type is 'Free Text Question'" do

    get '/en/online_quizzes/get_quiz_list_angular', params: {lecture_id: 3}, headers: @headers

    decode_json_response_body['quizList'].each do |q| 
      if q['question_type']=="Free Text Question" && OnlineAnswer.where(online_quiz_id: q['id']).blank?
        assert_equal q['match_type'], "Free Text"
      end
      
    end
  end

  test "should add match_type='Match Text' attribute to quiz " do ## in case question_type is 'Free Text Question' && online_answers.size > 0 && !online_answers.first.answer.blank?

    get '/en/online_quizzes/get_quiz_list_angular', params: {lecture_id: 3}, headers: @headers


    decode_json_response_body['quizList'].each do |q| 
      if q['question_type']=="Free Text Question" && OnlineAnswer.where(online_quiz_id: q['id']).count > 0 && !OnlineAnswer.where(online_quiz_id: q['id']).first.answer.blank?
        assert_equal q['match_type'], "Match Text"
      end
    end
  end

  test "vote_for_review " do 

    quiz = OnlineQuiz.find(1)
    assert_not quiz.online_quiz_grades.empty?
    quiz.online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], false
    end

    post '/en/online_quizzes/1/vote_for_review', params: {}, headers: @headers2

    quiz.reload
    
    quiz.online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], true
    end
  end

  test "unvote_for_review " do 

    OnlineQuizGrade.find(1).update_attribute("review_vote", true)
    
    quiz = OnlineQuiz.find(1)
    assert_not quiz.online_quiz_grades.empty?
    quiz.online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], true
    end

    post '/en/online_quizzes/1/unvote_for_review', params: {}, headers: @headers2

    quiz.reload
    
    quiz.online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], false
    end
  end


  test "vote_for_review for free text and html/drag" do 

    quiz = OnlineQuiz.find(2)
    assert_not quiz.free_online_quiz_grades.empty?
    quiz.free_online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], false
    end

    post '/en/online_quizzes/2/vote_for_review', params: {}, headers: @headers2

    quiz.reload
    quiz.free_online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], true
    end
  end
  
  test "unvote_for_review for free text and html/drag" do 

    FreeOnlineQuizGrade.find(1).update_attribute("review_vote", true)
    quiz = OnlineQuiz.find(2)
    assert_not quiz.free_online_quiz_grades.empty?
    quiz.free_online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], true
    end

    post '/en/online_quizzes/2/unvote_for_review', params: {}, headers: @headers2

    quiz.reload
    quiz.free_online_quiz_grades.each do |grade|
      assert_equal grade["review_vote"], false
    end
  end

  test "hide_responses should hide/show free_online_quiz_grades" do

    assert_changes 'FreeOnlineQuizGrade.find(1).hide', from: true, to: false do
      post '/en/online_quizzes/2/hide_responses?course_id=3', params:{hide:{hide: false, id: 1}}, headers: @headers, as: :json
    end

    assert_changes 'FreeOnlineQuizGrade.find(1).hide', from: false, to: true do
      post '/en/online_quizzes/2/hide_responses?course_id=3', params:{hide:{hide: true, id: 1}}, headers: @headers, as: :json
    end
  end

  test "update_grade should update free_online_quiz_grade of question" do
    assert_changes 'FreeOnlineQuizGrade.find(1).grade', from: 0, to: 3 do
      post '/en/online_quizzes/2/update_grade?course=3', params: {answer_id: 1, grade: 3}, headers:@headers, as: :json
    end
  end

   test "get_chart_data should " do
   		OnlineQuiz.find(1).update_attributes(inclass: true, hide:false, intro: 30, self: 60, in_group: 90, discussion: 120)
      OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:6, online_quiz_id:1, online_answer_id:6, grade:1, inclass:true, attempt:1,in_group:true)
      OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:7, online_quiz_id:1, online_answer_id:6, grade:1, inclass:true, attempt:1,in_group:false)
      OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:8, online_quiz_id:1, online_answer_id:7, grade:0, inclass:true, attempt:1,in_group:true)
      OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:8, online_quiz_id:1, online_answer_id:7, grade:0, inclass:true, attempt:2,in_group:false)
      get '/en/online_quizzes/1/get_chart_data', headers:@headers

    #  [self_first_try_grades_count, first_try_color, answer.answer , not_self_first_try_grades_count, group_first_try_grades_count, not_group_first_try_grades_count]
      assert_equal  decode_json_response_body, {"chart"=>
          {"6"=>[2, "green", "answer1", 0, 1, 0],
          "7"=>[0, "orange", "answer2", 1, 1, 0],
          "8"=>[2, "gray", "Never tried", 0, 3]}}
  end

  test "get_inclass_session_votes" do
    OnlineQuizGrade.find(1).destroy

    OnlineQuiz.find(1).update_attributes(inclass: true, hide:false, intro: 30, self: 60, in_group: 90, discussion: 120)
    Lecture.find(3).update_attribute('inclass',true)

    OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:6, online_quiz_id:1, online_answer_id:6, grade:1, inclass:true, attempt:1,in_group:true)
    OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:7, online_quiz_id:1, online_answer_id:6, grade:1, inclass:true, attempt:1,in_group:true)
    OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:8, online_quiz_id:1, online_answer_id:6, grade:1, inclass:true, attempt:1,in_group:true)
    OnlineQuizGrade.create(lecture_id:3, group_id:3, course_id:3, user_id:7, online_quiz_id:1, online_answer_id:6, grade:1, inclass:true, attempt:1,in_group:false)

    # self votes
    get '/en/online_quizzes/1/get_inclass_session_votes',params:{in_group:false,lecture_id:3}, headers: @headers

    assert_equal decode_json_response_body, {"votes"=>1, "max_votes"=>3}
    #in_group votes
    get '/en/online_quizzes/1/get_inclass_session_votes',params:{in_group:true,lecture_id:3}, headers: @headers

    assert_equal decode_json_response_body, {"votes"=>3, "max_votes"=>3}
  end
  
  

end
